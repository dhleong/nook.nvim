local M = {}

---@param transport_ids string[]
function M.find_first(params, transport_ids)
  for _, id in ipairs(transport_ids) do
    -- TODO: load the *configured* adapter
    local transport = require("nook.transport." .. id):new()
    local ok, result = pcall(function()
      return transport:connect(params)
    end)
    if ok and result then
      return transport
    elseif not ok then
      -- TODO: debug logging?
    end
  end
end

return M
