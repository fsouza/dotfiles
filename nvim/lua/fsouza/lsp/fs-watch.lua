local watch_kind = {Create = 1, Change = 2, Delete = 4}
local file_change_type = {Created = 1, Changed = 2, Deleted = 3}

-- The variable "state" maps a folder to a table in the following shape:
--
-- {
--   event = ..., -- the luv event handler
--   watchers = ... -- list of Watcher (see shape below)
-- }
--
-- The shape for the watcher is:
--
-- {
--   reg_id = ..., -- the id of the registration that added this watcher
--   client_id = ..., -- the client-id that registered this watcher
--   pattern = ..., -- pattern for this watcher
--   kind = ... -- kind of events of interest
-- }
local state = {}
local registrations = {}

local function reg_key(reg_id, client_id)
  return string.format("%d/%s", client_id, reg_id)
end

local function delete_registration(reg_id, client_id)
  local key = reg_key(reg_id, client_id)
  registrations[key] = nil
  
  for folder, entry in pairs(state) do
    local event = entry.event
    local watchers = entry.watchers
    local new_watchers = {}
    
    for _, watcher in ipairs(watchers) do
      if watcher.reg_id ~= reg_id then
        table.insert(new_watchers, watcher)
      end
    end
    
    if #new_watchers == 0 then
      vim.uv.fs_event_stop(event)
      state[folder] = nil
    else
      state[folder] = {event = event, watchers = new_watchers}
    end
  end
end

local function start_notifier(interval_ms)
  local client_notifications = {}
  interval_ms = interval_ms or 200
  local timer = vim.uv.new_timer()
  
  local function notify(client_id, reg_id, changes)
    local client = vim.lsp.get_client_by_id(client_id)
    if client then
      client:notify("workspace/didChangeWatchedFiles", {changes = changes})
    else
      delete_registration(reg_id, client_id)
    end
  end
  
  local function timer_cb()
    for _, notification in pairs(client_notifications) do
      local client_id = notification.client_id
      local reg_id = notification.reg_id
      local changes_map = notification.changes
      
      local changes = {}
      for uri, type in pairs(changes_map) do
        table.insert(changes, {uri = uri, type = type})
      end
      
      vim.schedule(function()
        notify(client_id, reg_id, changes)
      end)
    end
    
    client_notifications = {}
  end
  
  vim.uv.timer_start(timer, interval_ms, interval_ms, timer_cb)
  
  return function(client_id, reg_id, uri, type)
    local key = reg_key(reg_id, client_id)
    local notification = client_notifications[key] or {
      client_id = client_id,
      reg_id = reg_id,
      changes = {}
    }
    
    notification.changes[uri] = type
    client_notifications[key] = notification
  end
end

local once = require("fsouza.lib.nvim-helpers").once
local start_notifier = once(start_notifier)

local function is_file_open(filepath)
  local path = require("fsouza.lib.path")
  
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      local abs_path = path.abspath(bufname)
      if abs_path == filepath then
        return true
      end
    end
  end
  
  return false
end

local function make_fs_event_handler(root_dir, notify_server)
  local backupext = vim.o.backupext
  local pl_path = require("fsouza.lib.path")
  local glob = require("fsouza.lib.glob")
  
  local function notify(client_id, reg_id, filepath, events, kind)
    local function try_notify_server(client_id, reg_id, uri, type, ordinal)
      if bit.band(kind, ordinal) ~= 0 then
        notify_server(client_id, reg_id, uri, type)
      end
    end
    
    local uri = vim.uri_from_fname(filepath)
    
    if events.rename then
      vim.uv.fs_stat(filepath, function(err, _)
        if err then
          try_notify_server(
            client_id, reg_id, uri, 
            file_change_type.Deleted, watch_kind.Delete
          )
        else
          vim.schedule(function()
            if is_file_open(filepath) then
              try_notify_server(
                client_id, reg_id, uri,
                file_change_type.Changed, watch_kind.Change
              )
            else
              try_notify_server(
                client_id, reg_id, uri,
                file_change_type.Created, watch_kind.Create
              )
            end
          end)
        end
      end)
    else
      try_notify_server(
        client_id, reg_id, uri,
        file_change_type.Changed, watch_kind.Change
      )
    end
  end
  
  return function(err, filename, events)
    if not err and 
       not vim.endswith(filename, backupext) and
       not vim.startswith(filename, ".git/") and
       not vim.startswith(filename, ".hg/") and
       not vim.endswith(filename, "4913") then
       
      local filepath = pl_path.abspath(pl_path.join(root_dir, filename))
      local watchers = state[root_dir].watchers
      
      vim.schedule(function()
        for _, watcher in ipairs(watchers) do
          local pattern = watcher.pattern
          local client_id = watcher.client_id
          local kind = watcher.kind
          local reg_id = watcher.reg_id
          
          if glob.match(pattern, filename) or glob.match(pattern, filepath) then
            notify(client_id, reg_id, filepath, events, kind)
          end
        end
      end)
    end
  end
end

local function make_event(root_dir, notify_server)
  local event = vim.uv.new_fs_event()
  local ok, err = vim.uv.fs_event_start(
    event, 
    root_dir, 
    {recursive = true},
    make_fs_event_handler(root_dir, notify_server)
  )
  
  if not ok then
    error(string.format("failed to start fsevent at %s: %s", root_dir, err))
  end
  
  return event
end

local function dedupe_watchers(entry)
  local unique_watchers = {}
  
  for _, watcher in ipairs(entry.watchers) do
    unique_watchers[vim.inspect(watcher)] = watcher
  end
  
  entry.watchers = vim.tbl_values(unique_watchers)
  return entry
end

local function workspace_folders(client)
  local folders = {}
  local ws_folders = client and client.workspace_folders or {}
  
  for _, folder in ipairs(ws_folders) do
    table.insert(folders, folder.name)
  end
  
  return folders
end

local function map_watchers(client, watchers)
  local glob = require("fsouza.lib.glob")
  local path = require("fsouza.lib.path")
  local folders = {}
  
  for _, folder in ipairs(workspace_folders(client)) do
    folders[folder] = {}
  end
  
  local abs_folders = {}
  
  for _, watcher in ipairs(watchers) do
    local pats = glob.break_glob(watcher.globPattern)
    local sample = pats[1]
    local is_abs = path.isabs(sample)
    
    for folder, _ in pairs(folders) do
      if path.isrel(sample, folder) then
        table.insert(folders[folder], watcher)
        is_abs = false
      end
    end
    
    if is_abs then
      for folder, _ in pairs(state) do
        if path.isrel(sample, folder) then
          folders[folder] = {watcher}
          is_abs = false
        end
      end
      
      if is_abs then
        table.insert(abs_folders, {watcher = watcher, pats = pats})
      end
    end
  end
  
  local function find_best_folder(folder)
    local curr = nil
    for f, _ in pairs(folders) do
      if path.isrel(folder, f) then
        curr = f
        break
      end
    end
    
    if not curr then
      local function find_existing(folder)
        local _, err = vim.uv.fs_stat(folder)
        if err then
          return find_existing(vim.fs.dirname(folder))
        else
          return folder
        end
      end
      
      return find_existing(folder)
    end
    
    return curr
  end
  
  for _, entry in ipairs(abs_folders) do
    local pats = entry.pats
    local watcher = entry.watcher
    
    for _, pat in ipairs(pats) do
      local stripped = glob.strip_special(pat)
      local folder = find_best_folder(stripped)
      local folder_watchers = folders[folder] or {}
      
      table.insert(folder_watchers, watcher)
      folders[folder] = folder_watchers
    end
  end
  
  return folders
end

local function register(client_id, reg_id, watchers)
  local notify_server = start_notifier()
  local key = reg_key(reg_id, client_id)
  
  if not registrations[key] then
    local client = vim.lsp.get_client_by_id(client_id)
    local folder_map = map_watchers(client, watchers)
    
    registrations[key] = true
    
    for folder, folder_watchers in pairs(folder_map) do
      local glob = require("fsouza.lib.glob")
      local entry = state[folder] or {
        watchers = {},
        event = make_event(folder, notify_server)
      }
      
      for _, watcher in ipairs(folder_watchers) do
        local ok, pattern = glob.compile(watcher.globPattern)
        
        if ok then
          table.insert(entry.watchers, {
            reg_id = reg_id,
            pattern = pattern,
            client_id = client_id,
            glob_pattern = watcher.globPattern,
            kind = watcher.kind or 7
          })
        else
          error(string.format("error compiling glob from server: %s", pattern))
        end
      end
      
      state[folder] = dedupe_watchers(entry)
    end
  end
end

return {
  register = register,
  unregister = delete_registration
}