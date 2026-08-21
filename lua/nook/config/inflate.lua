---@class NookContext
---@field bufnr number

---@param ctx NookContext
local function inflate_part(ctx, config)
  if config == false then
    return false
  end

  if type(config) == "function" then
    return config(ctx)
  end

  if type(config) == "table" then
    for k, v in pairs(config) do
      config[k] = inflate_part(v, ctx)
    end
    for i, v in ipairs(config) do
      config[i] = inflate_part(v, ctx)
    end
  end

  return config
end

---@param ctx NookContext
local function inflate_adapter_config(ctx, configs)
  local each_part = vim.tbl_map(function(part)
    return inflate_part(ctx, part)
  end, configs)

  return vim.tbl_deep_extend("force", unpack(each_part))
end

return inflate_adapter_config
