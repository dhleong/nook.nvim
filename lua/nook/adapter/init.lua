local M = {
  ---@type table<string|number, NookBufConfig>
  _configs = {},
}

---@param bufnr number
function M._identify_bufnr(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, client in ipairs(clients) do
    if client.root_dir then
      return client.root_dir
    end
  end

  -- TODO: What if no lsp clients are configured?
end

---@param bufnr number
---@return NookBufConfig?
function M.config_for_bufnr(bufnr)
  -- NOTE: If we're quick, we might call this before
  -- the lsp clients have a chance to initialize,
  -- resulting in us starting without a key. To
  -- preserve the existing transports we fall back to
  -- keying on bufnr and "upgrade" if we later have
  -- a key for the bufnr.
  -- This is somewhat janky but is sufficient for now.
  local b = bufnr
  if b == 0 then
    b = vim.fn.bufnr("%")
  end

  local id = M._identify_bufnr(b)
  local key = id or b
  local config = M._configs[key] or M._configs[b]
  if config then
    if id and not config.key then
      config.key = id
      M._configs[id] = config
    end
    return config
  end

  local new_config = require("nook.config").create_buffer_config(b)
  new_config.key = id
  if not new_config then
    return nil
  end

  M._configs[key] = new_config
  return new_config
end

---@param bufnr number
---@return NookAdapter?
function M.for_bufnr(bufnr)
  local config = M.config_for_bufnr(bufnr)
  if config then
    return config.adapter
  end
end

---@return NookAdapter?
function M.get()
  return M.for_bufnr(vim.fn.bufnr("%"))
end

---@return NookBufConfig?
function M.get_config()
  return M.config_for_bufnr(vim.fn.bufnr("%"))
end

function M.reset_bufnr(bufnr)
  local id = M._identify_bufnr(bufnr)
  local config = M._configs[id or bufnr]
  if config then
    return config.adapter:destroy()
  end
end

return M
