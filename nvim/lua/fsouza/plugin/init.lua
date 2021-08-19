local vcmd = vim.cmd
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local function config_fzf_lua()
  local config = require('fzf-lua.config')
  config.globals.fzf_layout = 'default'
  config.globals.default_previewer = 'cat'
  config.globals.previewers.cat.args = ''
  config.globals.files.file_icons = false
  config.globals.files.git_icons = false
  config.globals.winopts.win_height = 0.65
  config.globals.winopts.win_width = 0.90
end

local function setup_fuzzy_mappings()
  helpers.create_mappings({
    n = {
      {
        lhs = '<leader>zb';
        rhs = helpers.fn_map(function()
          require('fzf-lua').buffers()
        end);
        opts = {silent = true};
      };
      {
        lhs = '<leader>zz';
        rhs = helpers.fn_map(function()
          require('fzf-lua').files()
        end);
        opts = {silent = true};
      };
      {
        lhs = '<leader>;';
        rhs = helpers.fn_map(function()
          require('fzf-lua').commands()
        end);
        opts = {silent = true};
      };
      {
        lhs = '<leader>zj';
        rhs = helpers.fn_map(function()
          local dir_path = vfn.expand('%:p:h')
          if vim.startswith(dir_path, '/') then
            require('fzf-lua').files({cwd = dir_path})
          end
        end);
        opts = {silent = true};
      };
      {
        lhs = '<leader>gg';
        rhs = helpers.fn_map(function()
          require('fzf-lua').grep()
        end);
        opts = {silent = true};
      };
      {
        lhs = '<leader>gw';
        rhs = helpers.fn_map(function()
          require('fzf-lua').grep_cword()
        end);
        opts = {silent = true};
      };
    };
  })
end

local function setup_autofmt_commands()
  vcmd([[command! ToggleAutofmt lua require('fsouza.lib.autofmt').toggle()]])
  vcmd([[command! ToggleGlobalAutofmt lua require('fsouza.lib.autofmt').toggle_g()]])
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
      targets = {'gitcommit'; 'markdown'; 'text'};
      command = [[setlocal spell]];
    };
  })
end

local function setup_editorconfig()
  require('fsouza.plugin.editor_config').enable()
  vim.schedule(function()
    vcmd([[command! EnableEditorConfig lua require('fsouza.plugin.editor_config').enable()]])
    vcmd([[command! DisableEditorConfig lua require('fsouza.plugin.editor_config').disable()]])
  end)
end

local function trigger_ft()
  vcmd('doautoall FileType')
end

local function setup_shortcuts()
  require('fsouza.plugin.shortcut').register('Dotfiles', vfn.expand('~/.dotfiles'))
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
  schedule(setup_fuzzy_mappings)
  schedule(config_fzf_lua)
  schedule(setup_hlyank)
  schedule(function()
    require('fsouza.plugin.mkdir').setup()
  end)
  schedule(setup_autofmt_commands)
  schedule(setup_word_replace)
  schedule(setup_spell)
  schedule(setup_shortcuts)
  schedule(function()
    require('colorizer').setup({'css'; 'javascript'; 'html'; 'lua'; 'htmldjango'})
  end)
  schedule(function()
    require('fsouza.plugin.ft').setup()
  end)
  schedule(setup_terminal_mappings_and_commands)
  schedule(function()
    require('fsouza.lsp')
  end)
  schedule(function()
    require('fsouza.plugin.ts')
  end)
  schedule(trigger_ft)
  schedule(function()
    vcmd([[doautocmd User PluginReady]])
  end)
end
