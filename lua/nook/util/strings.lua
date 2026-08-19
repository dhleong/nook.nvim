local M = {}

---Very simple string split that works in async contexts
---@param s string
---@param separator string
function M.split(s, separator)
  local result = {}
  local start = 1
  while true do
    local sep_start, sep_end = string.find(s, separator, start, true)
    if not sep_start then
      table.insert(result, #result + 1, string.sub(s, start))
      return result
    end

    table.insert(result, #result + 1, string.sub(s, start, sep_start - 1))
    start = sep_end + 1
  end
end

---@param s string
---@param separator string
function M.split_one(s, separator)
  local sep_start, sep_end = string.find(s, separator, 0, true)
  if not sep_start then
    return { s }
  end
  return { string.sub(s, 1, sep_start - 1), string.sub(s, sep_end + 1) }
end

---@param s? string
function M.trim(s)
  if not s then
    return nil
  end

  -- Would two finds + a sub be faster?
  return s:match("^%s*(.-)%s*$")
end

return M
