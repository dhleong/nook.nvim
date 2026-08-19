---@class NookEvaluateRequest
---@field code string
---@field raw? boolean

---@class NookTransport
---@field connect fun()
---@field destroy fun()
---@field evaluate fun(self: NookTransport, input: string|NookEvaluateRequest)

local M = {}

---@param input string|NookEvaluateRequest
---@return NookEvaluateRequest
function M.normalize_evaluate(input)
  if type(input) == "string" then
    return { code = input }
  end
  return input
end

return M
