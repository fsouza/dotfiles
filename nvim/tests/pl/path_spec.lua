local path = require("fsouza.pl.path")
local block_on = require("fsouza.lib.async-test")["block-on"]

describe("isrel", function()
  local isrel = path.isrel

  it("isrel", function()
    assert.is_true(isrel("/tmp/a/b/c", "/tmp"))
    assert.is_not_true(isrel("/tmp/a/b/c", "/tmp/b"))
  end)
end)

describe("async-mkdir", function()
  local async_mkdir = path["async-mkdir"]
  local base_dir = "/tmp"
  local temp_dir = path.join(base_dir, "tests")

  before_each(function()
    vim.fn.system("rm -rf " .. vim.fn.shellescape(temp_dir))
    vim.fn.mkdir(temp_dir)
  end)

  it("can create a simple dir", function()
    local dir = path.join(temp_dir, "a")
    local result = block_on(1000, async_mkdir, dir, 493, false)
    assert.is_true(#result == 0)

    assert.is_true(path.isdir(dir))
  end)

  it("can create dirs recursively", function()
    local dir = path.join(temp_dir, "a", "b", "c", "d")
    local result = block_on(1000, async_mkdir, dir, 493, true)
    assert.is_true(#result == 0)

    assert.is_true(path.isdir(path.join(temp_dir, "a")))
    assert.is_true(path.isdir(path.join(temp_dir, "a", "b")))
    assert.is_true(path.isdir(path.join(temp_dir, "a", "b", "c")))
    assert.is_true(path.isdir(path.join(temp_dir, "a", "b", "c")))
    assert.is_true(path.isdir(path.join(temp_dir, "a", "b", "c", "d")))
  end)

  it("fails if dir already exist and creation isn't recursive", function()
    local dir = path.join(temp_dir, "a")
    vim.fn.mkdir(dir)
    local result = block_on(1000, async_mkdir, dir, 493, false)
    assert.is_true(#result == 1)
    assert.are_same("EEXIST", require("fsouza.lib.nvim-helpers")["extract-luv-error"](result[1]))
  end)

  it("doesn't fail if dir already exist and creation is recursive", function()
    local dir = path.join(temp_dir, "a")
    vim.fn.mkdir(dir)
    local result = block_on(1000, async_mkdir, dir, 493, true)
    assert.is_true(#result == 0)
  end)
end)

describe("async-which", function()
  local async_which = path["async-which"]

  it("can check ls", function()
    local expected = vim.trim(vim.fn.system("which ls"))
    local result = block_on(1000, async_which, "ls")

    assert.are_same(expected, result[1])
  end)

  it("can take full path", function()
    local expected = vim.trim(vim.fn.system("which ls"))
    local result = block_on(1000, async_which, expected)

    assert.are_same(expected, result[1])
  end)

  it("empty string for thigns that can't be found", function()
    local result = block_on(1000, async_which, "something-that-hopefully-doesnt-exist")

    assert.are_same("", result[1])
  end)
end)
