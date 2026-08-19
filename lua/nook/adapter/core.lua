---@class NookAdapter
---@field connect async fun()
---@field evaluate async fun(input: string|NookAdapterEvaluateRequest): string

---@class NookAdapterEvaluateRequest
---@field bufnr number
---@field code string

local M = {}

---@param input string|NookAdapterEvaluateRequest
---@return NookAdapterEvaluateRequest
function M.normalize(input)
  if type(input) == "string" then
    return { code = input, bufnr = 0 }
  end
  return input
end

return M
