local wezterm = require('wezterm')

local tab_color_bg = '#afafaf'

local inactive_tab_colors = {fg_color = '#262626'; bg_color = tab_color_bg}

local function get_keys()
  local keys = {
    {
      key = '|';
      mods = 'LEADER';
      action = wezterm.action {SplitHorizontal = {domain = 'CurrentPaneDomain'}};
    };
    {
      key = '-';
      mods = 'LEADER';
      action = wezterm.action {SplitVertical = {domain = 'CurrentPaneDomain'}};
    };
    {key = 'c'; mods = 'LEADER'; action = wezterm.action {SpawnTab = 'CurrentPaneDomain'}};
    {key = 'x'; mods = 'LEADER'; action = wezterm.action {CloseCurrentTab = {confirm = false}}};
    {key = 'w'; mods = 'LEADER'; action = 'ShowTabNavigator'};
    {key = 'q'; mods = 'SUPER'; action = 'QuitApplication'};
  }

  return keys
end

return {
  colors = {
    background = '#ececec';
    foreground = '#000000';
    ansi = {'#000000'; '#c91b00'; '#00c200'; '#606000'; '#0225c7'; '#c930c6'; '#00c5c7'; '#c7c7c7'};
    brights = {
      '#000000';
      '#f2201f';
      '#23aa00';
      '#efef00';
      '#1a8fff';
      '#fd28ff';
      '#00c5c7';
      '#c7c7c7';
    };
    selection_bg = '#ffd787';
    tab_bar = {
      background = tab_color_bg;
      active_tab = {fg_color = '#262626'; bg_color = '#d0d0d0'; intensity = 'Bold'};
      inactive_tab = inactive_tab_colors;
      inactive_tab_hover = inactive_tab_colors;
      new_tab = inactive_tab_colors;
      new_tab_hover = inactive_tab_colors;
    };
  };
  default_prog = {'/usr/local/bin/zsh'; '-l'};
  disable_default_key_bindings = true;
  enable_tab_bar = false;
  font = wezterm.font('Source Code Pro');
  font_size = 12;
  force_reverse_video_cursor = true;
  keys = get_keys();
  leader = {key = ' '; mods = 'CTRL'; timeout_milliseconds = 1000};
  mouse_bindings = {
    {
      event = {Up = {streak = 1; button = 'Left'}};
      mods = 'NONE';
      action = wezterm.action {CompleteSelection = 'PrimarySelection'};
    };

    {
      event = {Up = {streak = 1; button = 'Left'}};
      mods = 'SUPER';
      action = 'OpenLinkAtMouseCursor';
    };
  };
  scrollback_lines = 50000;
  unix_domains = {{name = 'unix'}};
  window_close_confirmation = 'NeverPrompt';
  window_padding = {top = 2; right = 2; bottom = 2; left = 2};
}
