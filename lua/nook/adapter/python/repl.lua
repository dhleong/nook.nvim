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
  local request = require("nook.adapter.core").normalize(ctx)
  return self.transport:evaluate(request.code)
end

return PythonReplAdapter
