---@class NookContext
---@field bufnr number

---@param ctx NookContext
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
    for i, v in ipairs(config) do
      config[i] = inflate_adapter_config(v, ctx)
    end
  end

  return config
end

return inflate_adapter_config
