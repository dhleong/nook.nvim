local InputHistory = require("nook.editor.input_history")

local function perform_input()
  -- TODO: More contextual prompt?
  return vim.fn.input("nook> ")
end

---@param config NookBufConfig
---@return string
local function history_key(config)
  return vim.bo[config.bufnr].filetype
end

local M = {
  _input_histories = vim.g.NOOK_REPL_HISTORIES or {},
}

local function input_with_history(entries)
  InputHistory.make_active(entries)

  local ok, input = pcall(perform_input)

  InputHistory.restore()

  return ok and input ~= "", input
end

function M._insert_history(key, input)
  if not M._input_histories[key] then
    M._input_histories[key] = {}
  end

  for i, candidate in ipairs(M._input_histories[key]) do
    if candidate == input then
      table.remove(M._input_histories[key], i)
      break
    end
  end
  M._input_histories[key][#M._input_histories[key] + 1] = input

  -- Copy over to the persisted var
  vim.g.NOOK_REPL_HISTORIES = M._input_histories
end

---@param config NookBufConfig
function M.prompt(config)
  local hkey = history_key(config)
  local history = M._input_histories[hkey] or {}

  local ok, input = input_with_history(history)
  if ok then
    M._insert_history(hkey, input)
  end

  return ok, input
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
