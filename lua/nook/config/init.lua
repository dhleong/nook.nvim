---@class NookConfig: NookOptions
local M = {}

---@class NookOptions
local defaults = {}

---@type NookOptions
local options

---@param opts? NookOptions
function M.setup(opts)
  options = vim.tbl_deep_extend("force", defaults, opts or {}) or {}
end

--- TODO: NookAdapter type
---@class NookBufConfig
---@field adapter NookAdapter
---@field bufnr number
local NookBufConfig = {}

---@return NookBufConfig
function M.create_buffer_config(bufnr)
  local b = bufnr or vim.fn.bufnr("%")
  -- TODO:
  return {
    adapter = require("nook.adapter.webpack"):new({ url = "localhost:3333" }),
    bufnr = b,
  }
end

setmetatable(M, {
  __index = function(_, key)
    if options == nil then
      return vim.deepcopy(defaults)[key]
    end
    ---@cast options NookConfig
    return options[key]
  end,
})

return M
