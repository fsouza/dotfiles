-- See docs for Diagnostic.Tags:
-- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#diagnosticTag
local function valid_diagnostic(d)
  local severity = d.severity or 1

  -- Check if severity is high enough (< 2) and none of the tags are "Unnecessary" (1)
  if severity >= 2 then
    return false
  end

  local tags = d.tags or {}
  for _, tag in ipairs(tags) do
    if tag == 1 then -- DiagnosticTag.Unnecessary
      return false
    end
  end

  return true
end

return {
  valid_diagnostic = valid_diagnostic,
}
