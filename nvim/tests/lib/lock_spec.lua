local lock = require("fsouza.lib.lock")
local path = require("fsouza.pl.path")

describe("with-lock", function()
  local with_lock = lock["with-lock"]
  local lockfile = "lockfile1"
  local dir = path.join("/tmp", "a")

  before_each(function()
    local cache_dir = vim.fn.stdpath("cache")
    vim.fn.mkdir(dir, "p")
    vim.fn.chdir(dir)
    vim.fn.system(
      "rm -rf " .. vim.fn.shellescape(path.join(cache_dir, "fsouza-locks", vim.fn.getcwd():sub(2)))
    )
  end)

  after_each(function()
    vim.fn.system("rm -rf " .. vim.fn.shellescape(dir))
  end)

  it("only one should succeed", function()
    local locks = {}

    for _ = 1, 10 do
      with_lock(lockfile, function()
        table.insert(locks, true)
      end)
    end

    local timeout = 1000
    local ok = vim.wait(timeout, function()
      return #locks > 0
    end, 100)
    assert.is_true(ok)
    assert.are.same(1, #locks)
  end)

  it("should auto-unlock on VimLeavePre", function()
    local lock_count = 0

    with_lock(lockfile, function()
      lock_count = lock_count + 1
    end)

    local timeout = 1000
    local ok = vim.wait(timeout, function()
      return lock_count > 0
    end, 100)
    assert.is_true(ok)

    vim.api.nvim_exec_autocmds({ "VimLeavePre" }, {})
    vim.defer_fn(function()
      with_lock(lockfile, function()
        lock_count = lock_count + 1
      end)
    end, 250)

    ok = vim.wait(timeout, function()
      return lock_count > 1
    end, 100)
    assert.is_true(ok)
  end)
end)

describe("unlock", function()
  local unlock = lock["unlock"]
  local lockfile = "lockfile1"
  local dir = path.join("/tmp", "a")

  before_each(function()
    local cache_dir = vim.fn.stdpath("cache")
    vim.fn.mkdir(dir, "p")
    vim.fn.chdir(dir)
    vim.fn.system(
      "rm -rf " .. vim.fn.shellescape(path.join(cache_dir, "fsouza-locks", vim.fn.getcwd():sub(2)))
    )
  end)

  after_each(function()
    vim.fn.system("rm -rf " .. vim.fn.shellescape(dir))
  end)

  it("only one should succeed", function()
    local lock_count = 0

    lock["with-lock"](lockfile, function()
      lock_count = lock_count + 1
      unlock(lockfile)
      lock["with-lock"](lockfile, function()
        lock_count = lock_count + 1
      end)
    end)

    local timeout = 1000
    local ok = vim.wait(timeout, function()
      return lock_count == 2
    end, 100)
    assert.is_true(ok)
  end)
end)
