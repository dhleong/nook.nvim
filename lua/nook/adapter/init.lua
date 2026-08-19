---@class NookAdapter
---@field connect async fun()
---@field evaluate async fun(input: string|NookAdapterEvaluateRequest): string

local M = {
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

  return vim.fn.getcwd(vim.fn.bufwinnr(bufnr))
end

---@param bufnr number
---@return NookAdapter
function M.for_bufnr(bufnr)
  local id = M._identify_bufnr(bufnr)
  local config = M._configs[id]
  if config then
    return config.adapter
  end

  local new_config = require("nook.config").create_buffer_config(bufnr)
  M._configs[id] = new_config
  return new_config.adapter
end

---@return NookAdapter
function M.get()
  return M.for_bufnr(vim.fn.bufnr("%"))
end

function M.reset_bufnr(bufnr)
  local id = M._identify_bufnr(bufnr)
  local config = M._configs[id]
  if config then
    return config.adapter:destroy()
  end
end

return M
