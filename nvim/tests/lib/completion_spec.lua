local completion = require("fsouza.lib.completion")

describe("fsouza.lib.completion filter", function()
  local filter = completion.filter

  it("should return max score if prefix is empty", function()
    local score = filter("", "whatever")
    assert.are.same(999, score)
  end)

  it("should return min score for matches that are too long", function()
    local score = filter("wteverrrrr", "whatever")
    assert.are.same(0, score)
  end)

  it("should return the score from fzy for a partial match", function()
    local fzy_score = require("fzy").score("wtever", "whatever")
    local score = filter("wtever", "whatever")
    assert.are.same(fzy_score, score)
  end)

  it("should return max score for total match", function()
    local score = filter("whatever", "whatever")
    assert.are.same(999, score)
  end)
end)
