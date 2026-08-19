---@class RemoteDebuggingTransportOpts
local defaults = {
  port = 9222,
}

---@class RemoteDebuggingTransportOpts
local RemoteDebuggingTransport = {}

---@param opts? RemoteDebuggingTransportOpts
function RemoteDebuggingTransport:new(opts)
  local o = vim.tbl_deep_extend("force", {}, opts or defaults)

  setmetatable(o, self)
  self.__index = self

  return o
end

function RemoteDebuggingTransport:connect()
  local ok, result = require("nook.transport.http").get_json("https://127.0.0.1/json")
  print("aha", ok, result)
  if not ok then
    return false
  end
  -- local ok2, result2 = require("nook.transport.http").get_json("https://jsonplaceholder.typicode.com/todos/2")
  -- print("oho", ok, result)
  return "return" .. vim.json.encode(result)
end

function RemoteDebuggingTransport:destroy()
  -- TODO:
end

function RemoteDebuggingTransport:evaluate(code)
  return "code " .. code
end

return RemoteDebuggingTransport
