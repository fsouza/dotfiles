local helpers = require("fsouza.lib.nvim-helpers")

describe("fsouza.lib.nvim-helpers augroup", function()
  local augroup = helpers.augroup

  it("should clear the augroup when no commands are provided", function()
    local group_name = "fsouza__test_group"
    local group = vim.api.nvim_create_augroup(group_name, { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter" }, { command = "echo hello", group = group })

    augroup(group_name, {})
    local autocmds = vim.api.nvim_get_autocmds({ group = group_name })
    assert.are.same({}, autocmds)
  end)

  it("should create the given autocmds", function()
    local group_name = "fsouza__test_group"
    local group = vim.api.nvim_create_augroup(group_name, { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter" }, { command = "echo hello", group = group })

    augroup(group_name, {
      {
        events = { "BufRead" },
        targets = { "*.py" },
        once = true,
        command = "echo hi",
      },
      {
        events = { "BufWritePre", "BufWritePost" },
        targets = { "*.py", "*.rb" },
        command = "echo bye",
        buflocal = false,
      },
    })

    local autocmds = vim.api.nvim_get_autocmds({ group = group_name })
    table.sort(autocmds, function(a1, a2)
      -- this is horrible x)
      a1.id = nil
      a2.id = nil

      if a1.pattern == a2.pattern then
        return a1.event < a2.event
      end
      return a1.pattern < a2.pattern
    end)

    -- this is kind of a bad assertion since it's asserting against neovim's
    -- representation of autocmds. If that changes too often I'll revisit.
    assert.are.same({
      {
        event = "BufReadPost",
        pattern = "*.py",
        once = true,
        command = "echo hi",
        buflocal = false,
        group = group,
        group_name = group_name,
      },
      {
        event = "BufWritePost",
        pattern = "*.py",
        once = false,
        command = "echo bye",
        buflocal = false,
        group = group,
        group_name = group_name,
      },
      {
        event = "BufWritePre",
        pattern = "*.py",
        once = false,
        command = "echo bye",
        buflocal = false,
        group = group,
        group_name = group_name,
      },
      {
        event = "BufWritePost",
        pattern = "*.rb",
        once = false,
        command = "echo bye",
        buflocal = false,
        group = group,
        group_name = group_name,
      },
      {
        event = "BufWritePre",
        pattern = "*.rb",
        once = false,
        command = "echo bye",
        buflocal = false,
        group = group,
        group_name = group_name,
      },
    }, autocmds)
  end)
end)

describe("fsouza.lib.nvim-helpers reset-augroup", function()
  local reset_augroup = helpers["reset-augroup"]

  it("should clear the augroup", function()
    local group_name = "fsouza__test_group"
    local group = vim.api.nvim_create_augroup(group_name, { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter" }, { command = "echo hello", group = group })

    reset_augroup(group_name)
    local autocmds = vim.api.nvim_get_autocmds({ group = group_name })
    assert.are.same({}, autocmds)
  end)
end)

describe("fsouza.lib.nvim-helpers once", function()
  local once = helpers.once

  it("should not call the function multiple times", function()
    local counter = 0
    local f = once(function()
      counter = counter + 1
    end)

    f()
    f()
    f()
    f()

    assert.are.same(1, counter)
  end)

  it("should cache the return value", function()
    local f = once(function()
      return { result = 1 }
    end)

    local t1 = f()
    local t2 = f()

    assert.are.same({ result = 1 }, t1)
    assert.are.equal(t1, t2)
  end)
end)

describe("fsouza.lib.nvim-helpers extract-luv-error", function()
  local extract_luv_error = helpers["extract-luv-error"]

  it("extracts the part before the colon", function()
    assert.are_same("EEXIST", extract_luv_error("EEXIST: file already exists: /tmp/a"))
  end)

  it("returns the string if it doesn't have a colon", function()
    assert.are_same("whatever", extract_luv_error("whatever"))
  end)
end)

describe("fsouza.lib.nvim-helpers hash-buffer", function()
  local hash_buffer = helpers["hash-buffer"]

  it("calculates sha256 from the buffer contents", function()
    local stub = require("luassert.stub")

    local lines = { "line1", "line2", "line3" }
    stub(vim.api, "nvim_buf_get_lines", lines)

    local expected_hash = require("lsha2").hash256(table.concat(lines, "\n"))
    local hash = hash_buffer(2)

    assert.are.same(expected_hash, hash)
    assert.stub(vim.api.nvim_buf_get_lines).was.called_with(2, 0, -1, true)

    vim.api.nvim_buf_get_lines:revert()
  end)
end)
