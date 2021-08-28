local M = {}

local callbacks = {}

function M.register(bufnr, cb)
  if not callbacks[bufnr] then
    callbacks[bufnr] = {cb}
  else
    table.insert(callbacks[bufnr], cb)
  end
end

function M.detach(bufnr)
  for _, cb in ipairs(callbacks[bufnr] or {}) do
    cb(bufnr)
  end

  callbacks[bufnr] = nil
end

return M
