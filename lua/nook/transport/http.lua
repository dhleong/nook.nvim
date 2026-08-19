local nio = require("nio")

---@class HttpRequest
---@field url string
---@field method string
---@field expect? string

local M = {}

---@param request HttpRequest
function M.request(request)
  local proc = nio.process.run({
    cmd = "curl",
    args = { "-s", request.url },
  })
  if not proc then
    return false, "Failed to spawn http request"
  end

  local result = proc.result(true)
  if result ~= 0 then
    local stderr, err = proc.stderr.read()
    proc.close()
    return false, stderr or err
  end

  local output, err = proc.stdout.read()
  proc.close()

  print("output=", output, "err=", err)
  if err ~= nil then
    return false, err
  elseif request.expect == "json" and output ~= nil then
    return vim.json.decode(output)
  else
    return output
  end
end

-- M.get_json = require("nook.util.async").asyncable(function(cb, url)
--   return M.request(cb, { method = "GET", url = url, expect = "json" })
-- end)

function M.get_json(url)
  return M.request({ method = "GET", url = url, expect = "json" })
end

return M
