local vcmd = vim.cmd
local vfn = vim.fn
local helpers = require('fsouza.lib.nvim_helpers')

local function setup_fuzzy_mappings()
  helpers.create_mappings({
    n = {
      {lhs = '<leader>zb'; rhs = helpers.cmd_map('FzfBuffers'); opts = {silent = true}};
      {lhs = '<leader>zz'; rhs = helpers.cmd_map('FzfFiles'); opts = {silent = true}};
      {lhs = '<leader>;'; rhs = helpers.cmd_map('FzfCommands'); opts = {silent = true}};
      {
        lhs = '<leader>zj';
        rhs = helpers.fn_map(require('fsouza.plugin.fuzzy').fuzzy_here);
        opts = {silent = true};
      };
      {
        lhs = '<leader>gg';
        rhs = helpers.fn_map(require('fsouza.plugin.fuzzy').rg);
        opts = {silent = true};
      };
      {
        lhs = '<leader>gw';
        rhs = helpers.fn_map(require('fsouza.plugin.fuzzy').rg_cword);
        opts = {silent = true};
      };
      {lhs = '<leader>gb'; rhs = helpers.cmd_map('FzfGBranches'); opts = {silent = true}};
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
        rhs = helpers.fn_map(require('fsouza.plugin.word_sub').run);
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

local function setup_prettierd()
  local auto_fmt_fts = {
    'json';
    'javascript';
    'typescript';
    'css';
    'html';
    'typescriptreact';
    'yaml';
  }
  helpers.augroup('auto_prettierd', {
    {
      events = {'FileType'};
      targets = auto_fmt_fts;
      command = helpers.fn_cmd(function()
        require('fsouza.plugin.prettierd').setup_autofmt(vim.fn.expand('<abuf>'))
      end);
    };
    {
      events = {'FileType'};
      targets = auto_fmt_fts;
      command = [[nmap <buffer> <silent> <leader>f ]] ..
        [[<cmd>lua require('fsouza.plugin.prettierd').format(vim.fn.expand('<abuf>'))<cr>]];
    };
  })
end

local function trigger_ft()
  if vim.bo.filetype and vim.bo.filetype ~= '' then
    vcmd([[doautocmd FileType ]] .. vim.bo.filetype)
  end
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
  vcmd([[command! -nargs=* Run lua require('fsouza.plugin.terminal').run_in_main_term(<f-args>)]])
  vcmd([[command! -nargs=* T lua require('fsouza.plugin.terminal').run_in_main_term(<f-args>)]])
end

do
  local schedule = vim.schedule
  schedule(function()
    require('fsouza.vim-plug').setup_command()
  end)
  schedule(function()
    require('fsouza.lib.cleanup').setup()
  end)
  schedule(setup_editorconfig)
  schedule(setup_fuzzy_mappings)
  schedule(setup_hlyank)
  schedule(function()
    require('fsouza.plugin.mkdir').setup()
  end)
  schedule(setup_autofmt_commands)
  schedule(setup_word_replace)
  schedule(setup_spell)
  schedule(setup_prettierd)
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
