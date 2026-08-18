local M = {}

function M.find_first(params, transports)
  for _, transport in ipairs(transports) do
    local ok = transport:connect(params)
    if ok then
      return transport
    end
  end
end

return M
