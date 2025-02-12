-- Convert Fennel macros and functions to Lua

-- Helper function to create hotkeys with key event simulation
local function make_hotkey(mod, key, mod_target, target)
  return hs.hotkey.new(mod, key,
    function()
      local key_event = hs.eventtap.event.newKeyEvent(mod_target, target, true)
      key_event:post()
    end,
    function()
      local key_event = hs.eventtap.event.newKeyEvent(mod_target, target, false)
      key_event:post()
    end,
    function()
      local key_event = hs.eventtap.event.newKeyEvent(mod_target, target, true)
      key_event:post()
    end)
end

local function set_readline_shortcuts(exception_apps)
  local function is_terminal(window)
    if not window then
      return false
    end
    
    local application = window:application()
    local app_name = ""
    if application then
      app_name = application:name()
    end
    app_name = string.lower(app_name)
    
    local function check_app(idx)
      if idx > #exception_apps then
        return false
      end
      
      local app = exception_apps[idx]
      if app == app_name then
        return true
      end
      return check_app(idx + 1)
    end
    
    return check_app(1)
  end
  
  local hks = {
    make_hotkey("ctrl", "n", {}, "down"),
    make_hotkey("ctrl", "p", {}, "up"),
    make_hotkey("ctrl", "f", {}, "right"),
    make_hotkey("ctrl", "b", {}, "left"),
    make_hotkey("ctrl", "w", {"alt"}, hs.keycodes.map.delete),
    make_hotkey("ctrl", "u", {"cmd"}, hs.keycodes.map.delete)
  }
  
  local terminal_filter = hs.window.filter.new(is_terminal)
  local not_terminal_filter = hs.window.filter.new(function(win) return not is_terminal(win) end)
  
  local function enable_hks()
    for _, hk in ipairs(hks) do
      hk:enable()
    end
  end
  
  local function disable_hks()
    for _, hk in ipairs(hks) do
      hk:disable()
    end
  end
  
  terminal_filter:subscribe(hs.window.filter.windowFocused, disable_hks)
  not_terminal_filter:subscribe(hs.window.filter.windowFocused, enable_hks)
  
  if not is_terminal(hs.window.focusedWindow()) then
    enable_hks()
  end
end

-- Main initialization
local prefix = {"cmd", "ctrl"}
hs.hotkey.bind(prefix, "R", hs.reload)
hs.hotkey.bind(prefix, "V", function()
  local pb_content = hs.pasteboard.getContents()
  if pb_content and #pb_content < 256 then
    hs.eventtap.keyStrokes(pb_content)
  end
end)

set_readline_shortcuts({"alacritty", "terminal", "code", "iterm2"})