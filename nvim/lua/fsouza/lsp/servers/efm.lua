local function start_efm(bufnr, cb)
  local mod_dir = vim.fs.joinpath(_G.dotfiles_dir, "nvim", "langservers")
  local servers = require("fsouza.lsp.servers")
  
  servers.start({
    bufnr = bufnr,
    cb = cb,
    opts = {autofmt = 1},
    config = {
      name = "efm",
      cmd = {
        "go",
        "run",
        "-C",
        mod_dir,
        "github.com/mattn/efm-langserver"
      },
      init_options = {documentFormatting = true},
      settings = {
        lintDebounce = "250ms",
        rootMarkers = {".git"},
        languages = {}
      }
    }
  })
end

local function should_add(current_tools, tool)
  for _, existing_tool in ipairs(current_tools) do
    if (tool.formatCommand and existing_tool.formatCommand == tool.formatCommand) or
       (tool.lintCommand and existing_tool.lintCommand == tool.lintCommand) then
      return false
    end
  end
  return true
end

local function add(bufnr, language, tools)
  local function update_config(client_id)
    local client = vim.lsp.get_client_by_id(client_id)
    if not client then return end
    
    local changed = false
    local settings = client.config.settings
    local current_tools = settings.languages[language] or {}
    
    for _, tool in ipairs(tools) do
      if should_add(current_tools, tool) then
        changed = true
        table.insert(current_tools, tool)
      end
    end
    
    if changed then
      settings.languages[language] = current_tools
      client.config.settings = settings
      client:notify("workspace/didChangeConfiguration", {settings = settings})
    end
  end
  
  if #tools > 0 then
    start_efm(bufnr, update_config)
  end
end

return {
  add = add
}