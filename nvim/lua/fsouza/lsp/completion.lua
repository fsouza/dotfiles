local api = vim.api
local vfn = vim.fn
local helpers = require("fsouza.lib.nvim_helpers")

local M = {}

local load_cmp = helpers.once(function()
  vim.cmd("packadd nvim-cmp")
  require("cmp_nvim_lsp").setup()
  return require("cmp")
end)

local function setup(bufnr)
  local cmp = load_cmp()
  require("cmp.config").set_buffer({
    completion = {autocomplete = false};
    mapping = {
      ["<c-y>"] = cmp.mapping.confirm({behavior = cmp.ConfirmBehavior.Replace; select = true});
    };
    snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end;
    };
    sources = {{name = "nvim_lsp"}};
    documentation = {border = "none"; winhighlight = "Normal:CmpDocumentation"};
    preselect = cmp.PreselectMode.None;
    formatting = {
      format = function(entry, vim_item)
        local menu = ({nvim_lsp = "LSP"})[entry.source.name] or entry.source.name
        vim_item.menu = "「" .. menu .. "」"
        return vim_item
      end;
    };
  }, bufnr)
end

local function cr_key_for_comp_info(comp_info)
  if comp_info.mode == "" then
    return "<cr>"
  end
  if comp_info.pum_visible == 1 and comp_info.selected == -1 then
    return "<c-e><cr>"
  end
  return "<cr>"
end

local cr_cmd = helpers.ifn_map(function()
  local r = cr_key_for_comp_info(vfn.complete_info())
  return api.nvim_replace_termcodes(r, true, false, true)
end)

function M.on_attach(bufnr)
  setup(bufnr)

  local complete_cmd = helpers.ifn_map(function()
    load_cmp().complete()
    return ""
  end)

  require("fsouza.color")["set-popup-cb"](function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local whl = vim.api.nvim_win_get_option(win, "winhighlight")
      if string.match(whl, "CmpDocumentation") then
        return win
      end
    end
  end)

  vim.schedule(function()
    helpers.create_mappings({
      i = {
        {lhs = "<cr>"; rhs = cr_cmd; opts = {noremap = true}};
        {lhs = "<c-x><c-o>"; rhs = complete_cmd; opts = {noremap = true}};
      };
    }, bufnr)
  end)
end

function M.on_detach(bufnr)
  if api.nvim_buf_is_valid(bufnr) then
    helpers.remove_mappings({i = {{lhs = "<cr>"}}}, bufnr)
  end

  -- probably a bad idea?
  require("cmp.config").buffers[bufnr] = nil
end

return M
