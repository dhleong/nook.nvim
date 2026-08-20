local strings = require("nook.util.strings")

---@class PythonReplAdapterOpts
local defaults = {
  ipython = {
    cmd = "ipython",
    args = nil,
  },
  python3 = {
    cmd = "python3",
    args = nil,
  },
}

---@class PythonReplAdapter: PythonReplAdapterOpts
---@field transport NookTransport?
local PythonReplAdapter = {}

---@param args? PythonReplAdapterOpts
function PythonReplAdapter:new(args)
  local o = vim.tbl_deep_extend("force", {
    name = "PythonReplAdapter",
  }, defaults, args or {})

  setmetatable(o, self)
  self.__index = self

  return o
end

function PythonReplAdapter:connect()
  if self.transport then
    -- TODO: validate
    return true
  end

  local CliTransport = require("nook.transport.cli")
  self.transport = require("nook.transport").find_first({
    CliTransport:new({
      cmd = self.ipython.cmd or "ipython",
      args = self.ipython.args or nil,
      env = {
        TERM = "dumb",
        IPY_TEST_SIMPLE_PROMPT = 1,
        NO_COLOR = 1,
      },
      is_prompt_line = function(line)
        return string.match(line, "In %[%d%]:") ~= nil
      end,
    }),
    CliTransport:new({
      cmd = "python3",
      skip_echoed_input = true,
      is_prompt_line = function(line)
        return string.find(line, ">>> ") == 1
      end,
    }),
  })

  return self.transport ~= nil
end

function PythonReplAdapter:destroy()
  local transport = self.transport
  if transport then
    self.transport:destroy()
    self.transport = nil
  end
end

function PythonReplAdapter:evaluate(ctx)
  if not self:connect() then
    error("Not connected")
  end

  local request = require("nook.adapter.core").normalize(ctx)

  -- Clean up the code for clean repl val
  local code = strings.trim(request.code) or ""
  if string.find(code, "[:\t]") then
    -- There may be a cleaner way of doing this, but
    -- this is a vague heuristic to try to ensure we
    -- don't leave the repl in a "waiting for you to
    -- complete the indented region" state
    code = code .. "\r"
  end

  return self.transport:evaluate(code)
end

return PythonReplAdapter
