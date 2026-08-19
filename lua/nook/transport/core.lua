---@class NookEvaluateRequest
---@field kind string
---@field code string
---@field raw? boolean

---@class NookTransport
---@field destroy function()
---@field evaluate function(string|NookEvaluateRequest)

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
