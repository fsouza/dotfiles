local vcmd = vim.cmd
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local function setup_fuzzy_mappings()
  local rg_opts =
    [[--column -n --hidden --no-heading --color=always -S --glob '!.git' --glob '!.hg']]

  helpers.create_mappings({
    n = {
      {
        lhs = '<leader>zb';
        rhs = helpers.fn_map(function()
          require('telescope.builtin').buffers()
        end);
        opts = {silent = true};
      };
      {
        lhs = '<leader>zz';
        rhs = helpers.fn_map(function()
          require('telescope.builtin').find_files()
        end);
        opts = {silent = true};
      };
      {
        lhs = '<leader>;';
        rhs = helpers.fn_map(function()
          require('telescope.builtin').commands()
        end);
        opts = {silent = true};
      };
      {
        lhs = '<leader>zj';
        rhs = helpers.fn_map(function()
          local dir_path = vfn.expand('%:p:h')
          if vim.startswith(dir_path, '/') then
            require('telescope.builtin').find_files({search_dirs = {dir_path}})
          end
        end);
        opts = {silent = true};
      };
      {
        lhs = '<leader>gg';
        rhs = helpers.fn_map(function()
          local search = vfn.input([[rg：]])
          if search ~= '' then
            require('telescope.builtin').grep_string({search = search; use_regex = true})
          end
        end);
        opts = {silent = true};
      };
      {
        lhs = '<leader>gw';
        rhs = helpers.fn_map(function()
          require('telescope.builtin').grep_string()
        end);
        opts = {silent = true};
      };
    };
    v = {
      {
        lhs = '<leader>gw';
        rhs = helpers.fn_map(function()
          local search = require('fsouza.lib.nvim_helpers').visual_selection()
          if string.find(search, '\n') then
            error('only single line selections are supported')
          end

          if search ~= '' then
            require('telescope.builtin').grep_string({search = search})
          end
        end);
        opts = {silent = true};
      };
    };
  })
end

local function setup_git_messenger()
  local load_git_messenger = helpers.once(function()
    vcmd([[packadd git-messenger.vim]])
  end)

  helpers.create_mappings({
    n = {
      {
        lhs = '<leader>gm';
        rhs = helpers.fn_map(function()
          load_git_messenger()
          vcmd('GitMessenger')
        end);
        opts = {noremap = true; silent = true};
      };
    };
  })
end

local function setup_autofmt_commands()
  vcmd([[command! ToggleAutofmt lua require('fsouza.lib.autofmt').toggle()]])
  vcmd([[command! ToggleGlobalAutofmt lua require('fsouza.lib.autofmt').toggle_g()]])
end

local function setup_lsp_commands()
  vcmd([[command! LspRestart lua require('fsouza.lsp.detach').restart()]])
end

local function setup_hlyank()
  helpers.augroup('yank_highlight', {
    {
      events = {'TextYankPost'};
      targets = {'*'};
      command = helpers.fn_cmd(function()
        require('vim.highlight').on_yank({higroup = 'HlYank'; timeout = 200; on_macro = false})
      end);
    };
  })
end

local function setup_word_replace()
  helpers.create_mappings({
    n = {
      {
        lhs = '<leader>e';
        rhs = helpers.fn_map(function()
          require('fsouza.plugin.word_sub').run()
        end);
        opts = {silent = true};
      };
    };
  })
end

local function setup_spell()
  helpers.augroup('auto_spell', {
    {
      events = {'FileType'};
      targets = {'changelog'; 'gitcommit'; 'markdown'; 'text'};
      command = [[setlocal spell]];
    };
  })
end

local function setup_editorconfig()
  require('fsouza.plugin.editorconfig').enable()
  vim.schedule(function()
    vcmd([[command! EnableEditorConfig lua require('fsouza.plugin.editorconfig').enable()]])
    vcmd([[command! DisableEditorConfig lua require('fsouza.plugin.editorconfig').disable()]])
  end)
end

local function trigger_ft()
  vcmd('doautoall FileType')
end

local function setup_shortcuts()
  require('fsouza.plugin.shortcut').register('Dotfiles', vfn.expand('~/.dotfiles'))
  require('fsouza.plugin.shortcut').register('Paqs', require('fsouza.packed').paq_dir)
end

local function setup_terminal_mappings_and_commands()
  helpers.create_mappings({
    n = {
      {
        lhs = '<c-t>j';
        rhs = helpers.fn_map(function()
          require('fsouza.plugin.terminal').open('j')
        end);
        opts = {silent = true};
      };
      {
        lhs = '<c-t>k';
        rhs = helpers.fn_map(function()
          require('fsouza.plugin.terminal').open('k')
        end);
        opts = {silent = true};
      };
      {
        lhs = '<c-t>l';
        rhs = helpers.fn_map(function()
          require('fsouza.plugin.terminal').open('l')
        end);
        opts = {silent = true};
      };
    };
  })
end

do
  local schedule = vim.schedule
  schedule(function()
    require('fsouza.packed').setup_command()
  end)
  schedule(function()
    require('fsouza.lib.cleanup').setup()
  end)
  schedule(setup_editorconfig)
  schedule(setup_git_messenger)
  schedule(setup_hlyank)
  schedule(function()
    require('fsouza.plugin.mkdir').setup()
  end)
  schedule(setup_autofmt_commands)
  schedule(setup_word_replace)
  schedule(setup_spell)
  schedule(setup_shortcuts)
  schedule(function()
    require('colorizer').setup({'css'; 'javascript'; 'html'; 'lua'; 'htmldjango'; 'yaml'})
  end)
  schedule(setup_terminal_mappings_and_commands)
  schedule(function()
    require('fsouza.lsp')
  end)
  schedule(function()
    require('fsouza.plugin.ts')
  end)
  schedule(setup_lsp_commands)
  schedule(function()
    require('fsouza.plugin.telescope')
  end)
  schedule(setup_fuzzy_mappings)
  schedule(trigger_ft)
  schedule(function()
    vcmd([[doautocmd User PluginReady]])
  end)
end
