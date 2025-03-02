local vendored_parsers_dir = vim.fs.joinpath(_G.config_dir, "vendor", "ts-parsers")
local vendored_parsers = {}
for entry, type in vim.fs.dir(vendored_parsers_dir) do
  if type == "directory" then
    vendored_parsers[entry] = vim.fs.joinpath(vendored_parsers_dir, entry)
  end
end

local parser_aliases = { ocaml_interface = "ocaml" }
for parser_name, target in pairs(parser_aliases) do
  vendored_parsers[parser_name] = vim.fs.joinpath(vendored_parsers_dir, target)
end

local parsers = require("nvim-treesitter.parsers")
local parser_configs = parsers.get_parser_configs()
local parser_keys = vim.tbl_keys(parser_configs)
for _, parser_key in ipairs(parser_keys) do
  if vendored_parsers[parser_key] == nil then
    parser_configs[parser_key] = nil
  else
    parser_configs[parser_key].install_info.url = vendored_parsers[parser_key]
  end
end

local configs = require("nvim-treesitter.configs")
configs.setup({
  highlight = {
    enable = true,
    disable = function(lang, bufnr)
      return lang == "json" and vim.api.nvim_buf_line_count(bufnr) == 1
    end,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["al"] = "@block.outer",
        ["il"] = "@block.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["a,"] = "@parameter.outer",
        ["i,"] = "@parameter.inner",
      },
    },
    swap = {
      enable = true,
      swap_next = { ["<leader>a"] = "@parameter.inner" },
      swap_previous = { ["<leader>A"] = "@parameter.inner" },
    },
  },
  ensure_installed = {},
  auto_install = true,
})
