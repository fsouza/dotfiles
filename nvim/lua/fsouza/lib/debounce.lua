local function debounce(interval_ms, f)
  local last_call = nil
  local timer = vim.uv.new_timer()
  
  local function make_call()
    if last_call then
      f(unpack(last_call))
      last_call = nil
    end
  end
  
  timer:start(interval_ms, interval_ms, make_call)
  
  return {
    call = function(...) last_call = {...} end,
    stop = function()
      timer:close()
      last_call = nil
    end,
    clear = function() last_call = nil end
  }
end

return {
  debounce = debounce
}