local M = {}

local loop = vim.loop

function M.debounce(interval_ms, fn)
  local timer = loop.new_timer()
  local last_call = nil

  local function make_call()
    if last_call then
      fn(unpack(last_call))
      last_call = nil
    end
  end
  timer:start(interval_ms, interval_ms, make_call)
  return {
    call = function(...)
      last_call = {...}
    end;
    stop = function()
      make_call()
      timer:close()
    end;
  }
end

return M
