local cmd = require("fsouza.lib.cmd")

local function run_cmd(prg, opts, input_data, timeout)
  timeout = tonumber(timeout or os.getenv("NVIM_TEST_TIMEOUT") or 500)
  local result = nil

  cmd.run(prg, opts, input_data, function(r)
    result = r
  end)
  local ok, _ = vim.wait(timeout, function()
    return result ~= nil
  end, 25)

  assert(ok, string.format("command didn't complete after %dms", timeout))
  return result
end

describe("fsouza.lib.cmd", function()
  it("can run a command and capture stdout & stderr", function()
    local result = run_cmd(
      "bash",
      { args = { "-c", "echo hi from stdout && echo >&2 hi from stderr" } }
    )

    assert.are.same(0, result["exit-status"])
    assert.are.same("hi from stdout\n", result.stdout)
    assert.are.same("hi from stderr\n", result.stderr)
  end)

  it("can send data to the command", function()
    local result = run_cmd("cat", { args = {} }, "hello there")

    assert.are.same(0, result["exit-status"])
    assert.are.same("hello there", result.stdout)
  end)
end)
