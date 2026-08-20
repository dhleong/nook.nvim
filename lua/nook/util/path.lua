--- Largely borrowing from nvim-lspconfig

local M = {}

local function escape_wildcards(path)
  return path:gsub("([%[%]%?%*])", "\\%1")
end

---@param bufnr number
---@param pattern string
function M.find_parent_of(bufnr, pattern)
  local startpath = vim.fn.expand("#" .. bufnr .. ":p")
  local match = M.search_ancestors(startpath, function(path)
    for _, p in ipairs(vim.fn.glob(table.concat({ escape_wildcards(path), pattern }, "/"), true, true)) do
      if vim.uv.fs_stat(p) then
        return path
      end
    end
    return nil
  end)

  if match ~= nil then
    local real = vim.uv.fs_realpath(match)
    return real or match -- fallback to original if realpath fails
  end
end

---@generic T
---@param startpath string
---@param func fun(path: string): T?
---@return T?
function M.search_ancestors(startpath, func)
  if func(startpath) then
    return startpath
  end
  local guard = 100
  for path in vim.fs.parents(startpath) do
    -- Prevent infinite recursion if our algorithm breaks
    guard = guard - 1
    if guard == 0 then
      return
    end

    if func(path) then
      return path
    end
  end
end

return M
