local M = {}

function M:new(args)
  local o = vim.tbl_deep_extend("force", {
    name = "RnHermesAdapter",
  }, args or {})

  setmetatable(o, self)
  self.__index = self

  return o
end

function M:destroy()
  -- TODO:
end

return M
