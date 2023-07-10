local ff = require("fsouza.lib.ff")

describe("is-enabled", function()
  local is_enabled = ff["is-enabled"]
  ff.enable("enabled-feature")
  ff.disable("disabled-feature")

  it("returns true when feature is enabled", function()
    assert.are.same(true, is_enabled("enabled-feature"))
  end)

  it("returns false when feature is disabled", function()
    assert.are.same(false, is_enabled("disabled-feature"))
  end)

  it("returns the default value when feature isn't defined", function()
    assert.are.same(nil, is_enabled("unknown-feature"))
  end)

  it("returns the custom default value when feature isn't defined", function()
    assert.are.same(true, is_enabled("unknown-feature", true))
    assert.are.same(false, is_enabled("unknown-feature", false))
  end)
end)
