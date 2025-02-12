local disabled_servers = {}

local function fnm_exec(command)
  local node_version = vim.fs.joinpath(_G.config_dir, "langservers", ".node-version")
  local cmd = {"fnm", "exec", "--using", node_version, "--"}
  for _, v in ipairs(command) do
    table.insert(cmd, v)
  end
  return cmd
end

local function ff(server_name)
  return "lsp-server-" .. server_name
end

local function with_executable(exec, cb)
  if not exec then return end
  
  local function fallback()
    vim.schedule(function()
      cb(vim.fn.exepath(exec), false)
    end)
  end
  
  if vim.startswith(exec, "/") then
    fallback()
  else
    local node_exec = vim.fs.joinpath(_G.config_dir, "langservers", "node_modules", ".bin", exec)
    vim.uv.fs_stat(node_exec, function(err, stat)
      if err then
        fallback()
      elseif stat.type == "file" then
        cb(node_exec, true)
      else
        fallback()
      end
    end)
  end
end

local function cwd_if_not_home()
  local cwd = vim.uv.cwd()
  local home = vim.uv.os_homedir()
  if cwd ~= home then
    return cwd
  end
  return nil
end

local function patterns_with_fallback(patterns, bufname)
  local file = vim.fs.find(patterns, {
    upward = true,
    path = vim.fs.dirname(bufname)
  })[1]
  
  if file then
    return vim.fs.dirname(file)
  else
    return cwd_if_not_home()
  end
end

local function should_start(bufnr, name)
  local ff_mod = require("fsouza.lib.ff")
  return ff_mod.is_enabled(ff(name), true) and 
         vim.api.nvim_buf_is_valid(bufnr) and
         vim.bo[bufnr].buftype ~= "nofile"
end

local function with_defaults(opts)
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.workspace.executeCommand = {dynamicRegistration = false}
  capabilities.workspace.didChangeWatchedFiles = {
    dynamicRegistration = true,
    relativePatternSupport = false
  }
  capabilities.textDocument.completion.completionItem.snippetSupport = false
  
  local defaults = {
    handlers = require("fsouza.lsp.handlers"),
    capabilities = capabilities,
    flags = {debounce_text_changes = 150}
  }
  
  return vim.tbl_deep_extend("force", defaults, opts)
end

local function file_exists(bufname, cb)
  vim.uv.fs_stat(bufname, function(err, _)
    cb(err == nil)
  end)
end

local function autofmt_priority(autofmt)
  if autofmt == true then
    return 1
  else
    return autofmt
  end
end

local function start(params)
  local config = params.config
  local find_root_dir = params.find_root_dir or cwd_if_not_home
  local bufnr = params.bufnr or vim.api.nvim_get_current_buf()
  local cb = params.cb or function() end
  local opts = params.opts or {}
  
  local exec = config.cmd and config.cmd[1]
  local name = config.name
  config = with_defaults(config)
  
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local uri_prefixes = {"jdtls://", "file://"}
  
  if should_start(bufnr, name) then
    config.root_dir = find_root_dir(bufname)
    
    local function start_()
      with_executable(exec, function(exe_path, is_node_bin)
        if exe_path and exe_path ~= "" then
          config.cmd[1] = exe_path
          
          if is_node_bin then
            config.cmd = fnm_exec(config.cmd)
          end
          
          vim.schedule(function()
            local client_id = vim.lsp.start(config, {bufnr = bufnr})
            
            if opts.autofmt then
              local formatting = require("fsouza.lsp.formatting")
              formatting.attach(bufnr, client_id, autofmt_priority(opts.autofmt))
            end
            
            if opts.auto_action ~= nil then
              local auto_action = require("fsouza.lsp.auto-action")
              auto_action.attach(bufnr, client_id, opts.auto_action)
            end
            
            if opts.diagnostic_filter ~= nil then
              local buf_diagnostic = require("fsouza.lsp.buf-diagnostic")
              buf_diagnostic.register_filter(name, opts.diagnostic_filter)
            end
            
            cb(client_id)
          end)
        end
      end)
    end
    
    -- check specific URI prefixes because some of them should not be sent to
    -- LSPs (e.g. fugitive://, oil://, ssh://)
    local is_valid_uri = false
    for _, prefix in ipairs(uri_prefixes) do
      if vim.startswith(bufname, prefix) then
        is_valid_uri = true
        break
      end
    end
    
    if is_valid_uri then
      start_()
    else
      file_exists(bufname, function(exists)
        if exists then
          start_()
        else
          vim.schedule(function()
            local augroup = require("fsouza.lib.nvim-helpers").augroup
            augroup(
              string.format("fsouza__lsp_start_after_save_%s_%d", name, bufnr),
              {
                {
                  events = {"BufWritePost"},
                  targets = {string.format("<buffer=%d>", bufnr)},
                  once = true,
                  callback = start_
                }
              }
            )
          end)
        end
      end)
    end
  end
end

local function enable_server(name)
  local ff_mod = require("fsouza.lib.ff")
  ff_mod.enable(ff(name))
end

local function disable_server(name)
  local ff_mod = require("fsouza.lib.ff")
  ff_mod.disable(ff(name))
end

return {
  start = start,
  patterns_with_fallback = patterns_with_fallback,
  disable_server = disable_server,
  enable_server = enable_server
}