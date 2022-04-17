local glob = require("fsouza.lib.glob")

describe("compile and match", function()
  it("should support compiling a valid glob and matching it later", function()
    local ok, matcher = glob.compile("**/*.go")
    assert.is_true(ok)
    assert.is_true(glob.match(matcher, "dir/subdir/file.go"))
    assert.is_not_true(glob.match(matcher, "dir/subdir/file.goo"))
    assert.is_not_true(glob.match(matcher, "dir/subdir/file.py"))
  end)

  it("should support literal globs", function()
    local ok, matcher = glob.compile("dir/subdir/file.py")
    assert.is_true(ok)
    assert.is_true(glob.match(matcher, "dir/subdir/file.py"))
    assert.is_not_true(glob.match(matcher, "dir/subdir/file.pyy"))
    assert.is_not_true(glob.match(matcher, "dir/subdir/file.go"))
  end)

  it("should support groups", function()
    local ok, matcher = glob.compile("**/*.{go,mod,work,sum}")
    assert.is_true(ok)
    assert.is_true(glob.match(matcher, "dir/subdir/nested/file.go"))
    assert.is_true(glob.match(matcher, "go.mod"))
    assert.is_true(glob.match(matcher, "go.work"))
    assert.is_true(glob.match(matcher, "go.sum"))
    assert.is_not_true(glob.match(matcher, "file.py"))
  end)

  it("should support ranges", function()
    local ok, matcher = glob.compile("f[aeiou]le.py")
    assert.is_true(ok)
    assert.is_true(glob.match(matcher, "file.py"))
    assert.is_true(glob.match(matcher, "fele.py"))
    assert.is_true(glob.match(matcher, "file.py"))
    assert.is_true(glob.match(matcher, "fole.py"))
    assert.is_true(glob.match(matcher, "fule.py"))
    assert.is_not_true(glob.match(matcher, "fzle.py"))

    ok, matcher = glob.compile("f[a-z]le.py")
    assert.is_true(ok)
    assert.is_true(glob.match(matcher, "file.py"))
    assert.is_true(glob.match(matcher, "fble.py"))
    assert.is_true(glob.match(matcher, "fcle.py"))
    assert.is_not_true(glob.match(matcher, "f3le.py"))
    assert.is_not_true(glob.match(matcher, "fAle.py"))
  end)

  it("should support question mark", function()
    local ok, matcher = glob.compile("f?le.py")
    assert.is_true(ok)
    assert.is_true(glob.match(matcher, "file.py"))
    assert.is_true(glob.match(matcher, "fele.py"))
    assert.is_true(glob.match(matcher, "file.py"))
    assert.is_true(glob.match(matcher, "fole.py"))
    assert.is_true(glob.match(matcher, "fule.py"))
    assert.is_true(glob.match(matcher, "fzle.py"))
    assert.is_not_true(glob.match(matcher, "fzle.pyy"))
  end)
end)

describe("break", function()
  it("should return a list", function()
    local parts = glob["break"]("**/*.go")
    assert.are.same({ "**/*.go" }, parts)
  end)

  it("should not break down ranges", function()
    local parts = glob["break"]("**/[abc].go")
    assert.are.same({ "**/[abc].go" }, parts)
  end)

  it("should break down group options", function()
    local parts = glob["break"]("**/*.{go,mod,work}")
    assert.are.same({ "**/*.go", "**/*.mod", "**/*.work" }, parts)
  end)

  it("full paths too", function()
    local parts = glob["break"](
      "{/home/user/src/project,/home/user/src/project/pkg1,/home/user/src/project/pkg2,/home/user/src/project/pkg3}"
    )
    assert.are.same({
      "/home/user/src/project",
      "/home/user/src/project/pkg1",
      "/home/user/src/project/pkg2",
      "/home/user/src/project/pkg3",
    }, parts)
  end)

  it("should break down group with special chars", function()
    local parts = glob["break"]("**/*.{go,mod,w?rk}")
    assert.are.same({ "**/*.go", "**/*.mod", "**/*.w?rk" }, parts)
  end)

  it("should break down nested groups", function()
    local parts = glob["break"]("**/*.{go,mod,w{ark,ork}}")
    assert.are.same({ "**/*.go", "**/*.mod", "**/*.wark", "**/*.work" }, parts)
  end)
end)

describe("strip", function()
  it("should strip up to the first special char", function()
    local src =
      "/usr/local/Cellar/python@3.10/3.10.2/Frameworks/Python.framework/Versions/3.10/lib/python3.10/lib-dynload/**"
    assert.are.same(
      "/usr/local/Cellar/python@3.10/3.10.2/Frameworks/Python.framework/Versions/3.10/lib/python3.10/lib-dynload",
      glob["strip-special"](src)
    )
  end)

  it("should return the value unchanged if no special characters are declared", function()
    local src =
      "/usr/local/Cellar/python@3.10/3.10.2/Frameworks/Python.framework/Versions/3.10/lib/python3.10/lib-dynload/"
    assert.are.same(
      "/usr/local/Cellar/python@3.10/3.10.2/Frameworks/Python.framework/Versions/3.10/lib/python3.10/lib-dynload/",
      glob["strip-special"](src)
    )
  end)

  it("should look back for the path component", function()
    local src =
      "/usr/local/Cellar/python@3.10/3.10.2/Frameworks/Python.framework/Versions/3.10/lib/python3.10/lib-d?nload/"
    assert.are.same(
      "/usr/local/Cellar/python@3.10/3.10.2/Frameworks/Python.framework/Versions/3.10/lib/python3.10",
      glob["strip-special"](src)
    )
  end)

  it("should handle special chars at the beginning", function()
    local src = "**/*.go"
    assert.are.same("", glob["strip-special"](src))
  end)
end)
