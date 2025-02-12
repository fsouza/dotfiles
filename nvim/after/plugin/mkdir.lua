local function run(bufname)
  local dir = vim.fs.dirname(bufname)
  vim.fn.mkdir(dir, "p")
end

local function register_for_buffer(bufnr)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local augroup = require("fsouza.lib.nvim-helpers").augroup

  if bufname ~= "" and string.find(bufname, "^%a+://") == nil then
    augroup("fsouza__mkdir_" .. bufnr, {
      {
        events = { "BufWritePre" },
        targets = { string.format("<buffer=%d>", bufnr) },
        once = true,
        callback = function()
          run(bufname)
        end,
      },
    })
  end
end

local augroup = require("fsouza.lib.nvim-helpers").augroup
augroup("fsouza__mkdir", {
  {
    events = { "BufNew" },
    targets = { "*" },
    callback = function(opts)
      register_for_buffer(opts.buf)
    end,
  },
})

for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
  register_for_buffer(bufnr)
end
