local vendored_parsers = {
  bash = true,
  c = true,
  cmake = true,
  cpp = true,
  css = true,
  cuda = true,
  diff = true,
  dockerfile = true,
  git_config = true,
  git_rebase = true,
  gitattributes = true,
  gitcommit = true,
  gitignore = true,
  go = true,
  gomod = true,
  gosum = true,
  gotmpl = true,
  graphql = true,
  hcl = true,
  helm = true,
  html = true,
  htmldjango = true,
  java = true,
  javascript = true,
  jinja = true,
  jinja_inline = true,
  jq = true,
  json = true,
  json5 = true,
  jsonc = true,
  jsonnet = true,
  kotlin = true,
  lua = true,
  make = true,
  markdown = true,
  markdown_inline = true,
  nginx = true,
  nix = true,
  ocaml = true,
  ocaml_interface = true,
  odin = true,
  perl = true,
  promql = true,
  proto = true,
  python = true,
  query = true,
  requirements = true,
  ruby = true,
  rust = true,
  scala = true,
  sql = true,
  starlark = true,
  swift = true,
  terraform = true,
  tmux = true,
  toml = true,
  tsx = true,
  typescript = true,
  vim = true,
  vimdoc = true,
  xml = true,
  yaml = true,
  zig = true,
}

local parsers = require("nvim-treesitter.parsers")
local parser_configs = parsers.get_parser_configs()
local parser_keys = vim.tbl_keys(parser_configs)
for _, parser_key in ipairs(parser_keys) do
  if vendored_parsers[parser_key] == nil then
    parser_configs[parser_key] = nil
  else
    parser_configs[parser_key].install_info.url = vim.fs.joinpath(_G.config_dir, "vendor", "ts-parsers", parser_key)
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
