local watch_kind = { Create = 1, Change = 2, Delete = 4 }
local file_change_type = { Created = 1, Changed = 2, Deleted = 3 }

-- State management
local subscriptions = {} -- Maps subscription_name -> { client_id, reg_id, folder, kind }
local registrations = {} -- Maps reg_key -> { subscription_names }
local connection = nil -- Singleton watchman connection
local watched_roots = {} -- Maps folder -> watch_root (from watch-project response)
local pending_subscriptions = {} -- Maps folder -> list of pending subscription requests

-- Subscription flow (async):
--
-- register() -> watch-project (async)
--                    |
--                    v
--           handle_message() receives response
--                    |
--                    v
--           process_pending_subscriptions() -> subscribe

local function reg_key(reg_id, client_id)
  return string.format("%d/%s", client_id, reg_id)
end

local function subscription_name(client_id, reg_id, folder)
  local folder_hash = vim.fn.sha256(folder):sub(1, 8)
  return string.format("nvim-lsp-%d-%s-%s", client_id, reg_id, folder_hash)
end

-- Notification batching
local function start_notifier(interval_ms)
  local client_notifications = {}
  interval_ms = interval_ms or 200
  local timer = vim.uv.new_timer()

  local function notify(client_id, changes)
    local client = vim.lsp.get_client_by_id(client_id)
    if client then
      client:notify("workspace/didChangeWatchedFiles", { changes = changes })
    end
  end

  local function timer_cb()
    for _, notification in pairs(client_notifications) do
      local client_id = notification.client_id
      local changes_map = notification.changes

      local changes = {}
      for uri, type in pairs(changes_map) do
        table.insert(changes, { uri = uri, type = type })
      end

      vim.schedule(function()
        notify(client_id, changes)
      end)
    end

    client_notifications = {}
  end

  vim.uv.timer_start(timer, interval_ms, interval_ms, timer_cb)

  return function(client_id, reg_id, uri, type)
    local key = reg_key(reg_id, client_id)
    local notification = client_notifications[key]
      or {
        client_id = client_id,
        reg_id = reg_id,
        changes = {},
      }

    notification.changes[uri] = type
    client_notifications[key] = notification
  end
end

local once = require("fsouza.lib.nvim-helpers").once
local start_notifier = once(start_notifier)

local function glob_to_expression(glob_pattern, watch_root)
  if watch_root and vim.startswith(glob_pattern, watch_root) then
    glob_pattern = glob_pattern:sub(#watch_root + 1)
    if vim.startswith(glob_pattern, "/") then
      glob_pattern = glob_pattern:sub(2)
    end
  end

  if glob_pattern == "" or glob_pattern == "**" then
    return { "true" }
  end

  local suffix = glob_pattern:match("^%*%*/%*%.([%w]+)$")
  if suffix then
    return { "suffix", suffix }
  end

  return { "match", glob_pattern, "wholename" }
end

local function get_sockname()
  local result = vim.fn.system("watchman get-sockname")
  if vim.v.shell_error ~= 0 then
    error("Failed to get watchman socket: " .. result)
  end
  local ok, data = pcall(vim.json.decode, result)
  if not ok or not data.sockname then
    error("Invalid watchman get-sockname response: " .. result)
  end
  return data.sockname
end

local function create_connection()
  local sockname = get_sockname()
  local pipe = vim.uv.new_pipe(false)
  local buffer = ""
  local notify_server = start_notifier()

  local function send(cmd)
    local json = vim.json.encode(cmd) .. "\n"
    pipe:write(json)
  end

  local function send_subscribe(watch_root, sub_request)
    local sub_name = sub_request.sub_name
    local glob_patterns = sub_request.glob_patterns
    local relative_root = sub_request.relative_root

    local expressions = {}
    for _, glob_pattern in ipairs(glob_patterns) do
      local expr = glob_to_expression(glob_pattern, watch_root)
      table.insert(expressions, expr)
    end

    local match_expr
    if #expressions == 1 then
      match_expr = expressions[1]
    else
      match_expr = { "anyof", unpack(expressions) }
    end

    local full_expr = {
      "allof",
      { "type", "f" },
      match_expr,
    }

    local subscribe_opts = {
      expression = full_expr,
      fields = { "name", "exists", "new", "type" },
    }

    if relative_root and relative_root ~= "" then
      subscribe_opts.relative_root = relative_root
    end

    send({
      "subscribe",
      watch_root,
      sub_name,
      subscribe_opts,
    })
  end

  local function process_pending_subscriptions(requested_folder, watch_root, relative_path)
    local pending = pending_subscriptions[requested_folder]
    if not pending then
      return
    end

    for _, sub_request in ipairs(pending) do
      sub_request.relative_root = relative_path
      send_subscribe(watch_root, sub_request)
    end

    pending_subscriptions[requested_folder] = nil
  end

  local function handle_subscription_event(msg)
    if msg.is_fresh_instance then
      return
    end

    local sub_name = msg.subscription
    local sub_info = subscriptions[sub_name]
    if not sub_info then
      return
    end

    local client_id = sub_info.client_id
    local reg_id = sub_info.reg_id
    local kind = sub_info.kind
    local folder = sub_info.folder

    for _, file in ipairs(msg.files or {}) do
      if
        not vim.endswith(file.name, vim.o.backupext)
        and not vim.startswith(file.name, ".git/")
        and not vim.startswith(file.name, ".hg/")
        and not vim.endswith(file.name, "4913")
      then
        local filepath = vim.fs.joinpath(folder, file.name)
        local uri = vim.uri_from_fname(filepath)

        local change_type = nil
        local change_kind = nil

        if file.new and file.exists then
          change_type = file_change_type.Created
          change_kind = watch_kind.Create
        elseif not file.exists then
          change_type = file_change_type.Deleted
          change_kind = watch_kind.Delete
        elseif file.exists then
          change_type = file_change_type.Changed
          change_kind = watch_kind.Change
        end

        if change_type and bit.band(kind, change_kind) ~= 0 then
          notify_server(client_id, reg_id, uri, change_type)
        end
      end
    end
  end

  local function handle_message(msg)
    if msg.error then
      vim.schedule(function()
        vim.notify("watchman error: " .. msg.error, vim.log.levels.ERROR)
      end)
    elseif msg.warning then
      vim.schedule(function()
        vim.notify("watchman warning: " .. msg.warning, vim.log.levels.WARN)
      end)
    elseif msg.unilateral and msg.subscription then
      vim.schedule(function()
        handle_subscription_event(msg)
      end)
    elseif msg.watch then
      -- watch-project response
      local watch_root = msg.watch
      local relative_path = msg.relative_path

      watched_roots[watch_root] = watch_root
      local requested_folder = watch_root
      if relative_path then
        requested_folder = vim.fs.joinpath(watch_root, relative_path)
        watched_roots[requested_folder] = watch_root
      end

      process_pending_subscriptions(requested_folder, watch_root, relative_path)
    end
  end

  local function on_read(err, chunk)
    if err then
      vim.schedule(function()
        vim.notify("watchman read error: " .. err, vim.log.levels.ERROR)
      end)
      return
    end

    if not chunk then
      -- Connection closed
      pipe:close()
      connection = nil
      return
    end

    buffer = buffer .. chunk

    -- Process newline-delimited JSON
    while true do
      local nl = buffer:find("\n")
      if not nl then
        break
      end

      local json_line = buffer:sub(1, nl - 1)
      buffer = buffer:sub(nl + 1)

      local ok, msg = pcall(vim.json.decode, json_line)
      if ok then
        handle_message(msg)
      end
    end
  end

  local connected = false
  local connect_err = nil

  pipe:connect(sockname, function(err)
    if err then
      connect_err = err
      return
    end
    connected = true
    pipe:read_start(on_read)
  end)

  -- Wait briefly for connection (synchronous for simplicity)
  vim.wait(1000, function()
    return connected or connect_err ~= nil
  end)

  if connect_err then
    error("Failed to connect to watchman: " .. connect_err)
  end

  if not connected then
    error("Timeout connecting to watchman")
  end

  return {
    send = send,
    send_subscribe = send_subscribe,
    close = function()
      pipe:close()
    end,
  }
end

local function get_connection()
  if not connection then
    connection = create_connection()
  end
  return connection
end

local function workspace_folders(client)
  local folders = {}
  local ws_folders = client and client.workspace_folders or {}

  for _, folder in ipairs(ws_folders) do
    table.insert(folders, folder.name)
  end

  return folders
end

local function delete_registration(reg_id, client_id)
  local key = reg_key(reg_id, client_id)
  local reg_info = registrations[key]

  if not reg_info then
    return
  end

  local conn = get_connection()

  for _, sub_name in ipairs(reg_info.subscription_names or {}) do
    local sub_info = subscriptions[sub_name]
    if sub_info then
      local watch_root = watched_roots[sub_info.folder] or sub_info.folder
      conn.send({ "unsubscribe", watch_root, sub_name })
      subscriptions[sub_name] = nil
    end
  end

  registrations[key] = nil
end

local function register(client_id, reg_id, watchers)
  local key = reg_key(reg_id, client_id)

  if registrations[key] then
    return
  end

  local client = vim.lsp.get_client_by_id(client_id)
  local folders = workspace_folders(client)

  if #folders == 0 then
    return
  end

  local conn = get_connection()
  local subscription_names = {}

  for _, folder in ipairs(folders) do
    local glob_patterns = {}
    local combined_kind = 0

    for _, watcher in ipairs(watchers) do
      local glob_pattern = watcher.globPattern
      local kind = watcher.kind or 7

      combined_kind = bit.bor(combined_kind, kind)
      table.insert(glob_patterns, glob_pattern)
    end

    local sub_name = subscription_name(client_id, reg_id, folder)

    subscriptions[sub_name] = {
      client_id = client_id,
      reg_id = reg_id,
      folder = folder,
      kind = combined_kind,
    }
    table.insert(subscription_names, sub_name)

    local sub_request = {
      sub_name = sub_name,
      glob_patterns = glob_patterns,
    }

    local watch_root = watched_roots[folder]
    if watch_root then
      if folder ~= watch_root then
        sub_request.relative_root = folder:sub(#watch_root + 2)
      end
      conn.send_subscribe(watch_root, sub_request)
    else
      local pending = pending_subscriptions[folder] or {}
      table.insert(pending, sub_request)
      pending_subscriptions[folder] = pending
      conn.send({ "watch-project", folder })
    end
  end

  registrations[key] = {
    subscription_names = subscription_names,
  }
end

return {
  register = register,
  unregister = delete_registration,
}
