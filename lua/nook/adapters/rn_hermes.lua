local M = {}

function M:new(args)
  local o = vim.tbl_deep_extend("force", {}, args)

  setmetatable(o, self)
  self.__index = self

  return o
end

return M
