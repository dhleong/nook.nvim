local M = {}

---@param transports NookTransport[]
function M.find_first(transports)
  local errors = {}
  for _, transport in ipairs(transports) do
    local ok, result = pcall(transport.connect, transport)
    if ok and result then
      return transport
    elseif not ok then
      -- TODO: debug logging?
      errors[#errors + 1] = result
    end
  end

  print(vim.inspect(errors))
  error("No transport was able to connect")
end

return M
