---@class NookContext
---@field bufnr number

---@alias Config<T> T|nil|fun(NookContext):T

---@class NookConfig: NookOptions
local M = {}

---@class NookOptions
local defaults = {
  adapters = {
    ---@type Config<PythonReplAdapterOpts>
    ["python.repl"] = nil,
  },
}

---@type NookOptions
local options

---@param opts? NookOptions
function M.setup(opts)
  options = vim.tbl_deep_extend("force", defaults, opts or {}) or {}
end

local function inflate_adapter_config(config, ctx)
  if config == false then
    return false
  end

  if type(config) == "function" then
    return config(ctx)
  end

  if type(config) == "table" then
    for k, v in pairs(config) do
      config[k] = inflate_adapter_config(v, ctx)
    end
  end

  return config
end

--- TODO: NookAdapter type
---@class NookBufConfig
---@field adapter NookAdapter
---@field bufnr number
local NookBufConfig = {}

---@param adapter_id string
---@param ctx NookContext
---@return NookBufConfig?
function M.create_adapter(adapter_id, ctx)
  local ok, Type = pcall(require, "nook.adapter." .. adapter_id)
  if not ok then
    error("Unknown adapter: " .. adapter_id)
  end

  local config = inflate_adapter_config(options.adapters[adapter_id], ctx)
  print("config=", vim.inspect(config))
  if config == false then
    return nil
  end

  return {
    adapter = Type:new(config),
    bufnr = ctx.bufnr,
  }
end

---@return NookBufConfig?
function M.create_buffer_config(bufnr)
  local b = bufnr
  if not b or b == 0 then
    b = vim.fn.bufnr("%")
  end
  -- TODO: User config pls

  local ctx = { bufnr = b }
  if vim.bo[bufnr].filetype == "python" then
    return M.create_adapter("python.repl", ctx)
  end

  return M.create_adapter("webpack", ctx)
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
