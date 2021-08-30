local conf = require('telescope.config').values
local finders = require('telescope.finders')
local make_entry = require('telescope.make_entry')
local pickers = require('telescope.pickers')

local M = {}

function M.send(items, prompt)
  prompt = prompt .. '：'
  local opts = {}

  pickers.new(opts, {
    prompt_title = prompt;
    finder = finders.new_table {results = items; entry_maker = make_entry.gen_from_quickfix(opts)};
    previewer = conf.qflist_previewer(opts);
    sorter = conf.generic_sorter(opts);
  }):find()
end

return M
