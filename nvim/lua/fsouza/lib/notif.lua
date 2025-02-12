local last_notification = nil
local messages = {}
local timer = nil
local MAX_WIDTH = 13

local function trim(msg)
  local width = MAX_WIDTH - 3
  return string.sub(msg, 1, width) .. "..."
end

local function record_message(msg)
  if #messages < 100 then
    table.insert(messages, {
      msg = msg,
      date = os.date("%b %d, %H:%M:%S")
    })
  end
end

local function notify(notification)
  record_message(notification.msg)
  
  local msg = notification.msg
  if #msg > MAX_WIDTH then
    msg = trim(msg)
  end
  
  last_notification = {msg = msg, age = notification.age}
  
  if timer ~= nil then
    timer:stop()
    timer:close()
    timer = nil
  end
end

local function get_notification()
  if last_notification then
    local msg = last_notification.msg
    local age = last_notification.age
    
    if timer == nil then
      timer = vim.uv.new_timer()
      timer:start(age, 0, function()
        timer:stop()
        timer:close()
        timer = nil
        last_notification = nil
      end)
    end
    
    return msg
  else
    return ""
  end
end

local function log_messages()
  for _, entry in ipairs(messages) do
    print(string.format("%s - %s", entry.date, entry.msg))
  end
  messages = {}
end

return {
  notify = notify,
  get_notification = get_notification,
  log_messages = log_messages
}