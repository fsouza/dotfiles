local vcmd = vim.cmd
local vfn = vim.fn

local function should_qf(selected)
  if #selected < 2 then
    return false
  end

  for _, sel in ipairs(selected) do
    if sel.lnum ~= nil then
      return true
    end
  end

  return false
end

local function edit(selected)
  for _, sel in ipairs(selected) do
    local file = sel[1]

    vcmd('edit ' .. vfn.fnameescape(file))
  end
end

local function edit_or_qf(prompt_bufnr)
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  local picker = action_state.get_current_picker(prompt_bufnr)
  local selected = picker:get_multi_selection()

  if #selected < 1 then
    return actions.file_edit(prompt_bufnr)
  end

  if should_qf(selected) then
    actions.send_selected_to_qflist(prompt_bufnr)
    actions.open_qflist()
    vcmd('cc')
  else
    actions.close(prompt_bufnr)
    edit(selected)
  end
end

do
  local telescope = require('telescope')
  local actions = require('telescope.actions')

  telescope.setup {
    defaults = {
      layout_config = {height = 0.75; width = 0.9};
      mappings = {
        i = {
          ['<esc>'] = actions.close;
          ['<a-a>'] = actions.toggle_all;
          ['<tab>'] = actions.toggle_selection + actions.move_selection_next;
          ['<s-tab>'] = actions.toggle_selection + actions.move_selection_previous;
          ['<cr>'] = edit_or_qf;
          ['<c-d>'] = actions.preview_scrolling_down;
          ['<c-u>'] = actions.preview_scrolling_up;
        };
      };
      vimgrep_arguments = {
        {
          'rg';
          '--color=never';
          '--no-heading';
          '--with-filename';
          '--line-number';
          '--column';
          '--smart-case';
          '--hidden';
          '--glob';
          '!.git';
          '--glob';
          '!.hg';
        };
      };
    };
    extensions = {
      fzf = {
        fuzzy = true;
        override_generic_sorter = true;
        override_file_sorter = true;
        case_mode = 'smart_case';
      };
    };
  }

  telescope.load_extension('fzf')
end
