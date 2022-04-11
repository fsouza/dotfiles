local wezterm = require('wezterm')

local tab_color_bg = '#cccccc'

local inactive_tab_colors = {fg_color = '#262626'; bg_color = tab_color_bg}

local function get_keys()
  local keys = {
    {key = 'c'; mods = 'SUPER'; action = wezterm.action({CopyTo = 'Clipboard'})};
    {key = 'v'; mods = 'SUPER'; action = wezterm.action({PasteFrom = 'Clipboard'})};
    {
      key = [[|]];
      mods = 'LEADER';
      action = wezterm.action({SplitHorizontal = {domain = 'CurrentPaneDomain'}});
    };
    {
      key = [[\]];
      mods = 'LEADER|SHIFT';
      action = wezterm.action({SplitHorizontal = {domain = 'CurrentPaneDomain'}});
    };
    {
      key = [[\]];
      mods = 'LEADER';
      action = wezterm.action({SplitHorizontal = {domain = 'CurrentPaneDomain'}});
    };
    {
      key = '-';
      mods = 'LEADER';
      action = wezterm.action({SplitVertical = {domain = 'CurrentPaneDomain'}});
    };
    {
      key = '_';
      mods = 'LEADER';
      action = wezterm.action({SplitVertical = {domain = 'CurrentPaneDomain'}});
    };
    {
      key = '-';
      mods = 'LEADER|SHIFT';
      action = wezterm.action({SplitVertical = {domain = 'CurrentPaneDomain'}});
    };
    {key = ' '; mods = 'LEADER|CTRL'; action = 'ActivateLastTab'};
    {key = 'c'; mods = 'LEADER'; action = wezterm.action({SpawnTab = 'CurrentPaneDomain'})};
    {key = 'x'; mods = 'LEADER'; action = wezterm.action({CloseCurrentTab = {confirm = false}})};
    {key = 'w'; mods = 'LEADER'; action = 'ShowTabNavigator'};
    {key = 'r'; mods = 'LEADER'; action = 'ReloadConfiguration'};
    {key = 'q'; mods = 'SUPER'; action = 'QuitApplication'};
    {key = 'Enter'; mods = 'LEADER'; action = 'ActivateCopyMode'};
    {key = 'h'; mods = 'LEADER'; action = wezterm.action({ActivatePaneDirection = 'Left'})};
    {key = 'l'; mods = 'LEADER'; action = wezterm.action({ActivatePaneDirection = 'Right'})};
    {key = 'k'; mods = 'LEADER'; action = wezterm.action({ActivatePaneDirection = 'Up'})};
    {key = 'j'; mods = 'LEADER'; action = wezterm.action({ActivatePaneDirection = 'Down'})};
    {key = ';'; mods = 'LEADER'; action = wezterm.action({ActivatePaneDirection = 'Next'})};
    {key = ';'; mods = 'LEADER|CTRL'; action = wezterm.action({ActivatePaneDirection = 'Next'})};
    {key = 'w'; mods = 'SUPER'; action = wezterm.action({CloseCurrentTab = {confirm = false}})};
  }

  for n = 1, 9 do
    table.insert(keys, {
      key = tostring(n);
      mods = 'LEADER';
      action = wezterm.action({ActivateTab = n - 1});
    })

    table.insert(keys, {
      key = tostring(n);
      mods = 'SUPER';
      action = wezterm.action({ActivateTab = n - 1});
    })
  end

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
      active_tab = {fg_color = '#262626'; bg_color = '#ececec'; intensity = 'Bold'};
      inactive_tab = inactive_tab_colors;
      inactive_tab_hover = inactive_tab_colors;
      new_tab = inactive_tab_colors;
      new_tab_hover = inactive_tab_colors;
    };
  };
  default_gui_startup_args = {'connect'; 'unix'};
  disable_default_key_bindings = true;
  enable_tab_bar = true;
  exit_behavior = "Close";
  font = wezterm.font('SauceCodePro Nerd Font Mono', {weight = 'Regular'});
  font_size = 12;
  force_reverse_video_cursor = true;
  hide_tab_bar_if_only_one_tab = true;
  inactive_pane_hsb = {saturation = 1.0; brightness = 1.0};
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
  scrollback_lines = 500000;
  tab_bar_at_bottom = true;
  unix_domains = {{name = 'unix'; connect_automatically = true; skip_permissions_check = false}};
  use_fancy_tab_bar = false;
  window_close_confirmation = 'NeverPrompt';
  window_padding = {top = 4; right = 10; bottom = 4; left = 10};
}
