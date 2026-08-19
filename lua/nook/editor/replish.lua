local function perform_input()
  -- TODO: More contextual prompt?
  return vim.fn.input("nook> ")
end

local M = {}

---@param _config NookBufConfig
function M.prompt(_config)
  -- TODO: history mgmt
  local ok, input = pcall(perform_input)
  return ok and input ~= "", input
end

---@param config NookBufConfig
function M.prompt_eval(config)
  -- Start ensuring we're connected asynchronously
  require("nio").run(function()
    config.adapter:connect()
  end)

  local ok, input = M.prompt(config)
  if ok then
    local result = config.adapter:evaluate(input)
    -- TODO: Store somewhere for :Last
    print(result)
  end
end

return M
