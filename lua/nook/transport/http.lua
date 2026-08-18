local nio = require("nio")

---@class HttpRequest
---@field url string
---@field method string
---@field expect? string

local M = {}

---@param request HttpRequest
function M.request(request)
  ---@param data vim.SystemCompleted
  --local function process_output(data)
  --  if request.expect == "json" then
  --    return vim.json.decode(data.stdout)
  --  else
  --    return data.stdout
  --  end
  --end

  -----@param data vim.SystemCompleted
  --local function on_exit(data)
  --  if data.code == 0 then
  --    cb(true, process_output(data))
  --  else
  --    cb(false, data)
  --  end
  --end

  --local req = { "curl", "-s", request.url }
  --local opts = { text = true }
  --if cb then
  --  print("invoke system async")
  --  vim.system(req, opts, on_exit)
  --else
  --  return vim.system(req, opts)
  --end

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
    return false, stderr or err
  end

  local result, err = proc.stdout.read()

  print("result=", result, "err=", err)
  if err ~= nil then
    return false, err
  elseif request.expect == "json" and result ~= nil then
    return vim.json.decode(result)
  else
    return result
  end
end

-- M.get_json = require("nook.util.async").asyncable(function(cb, url)
--   return M.request(cb, { method = "GET", url = url, expect = "json" })
-- end)

function M.get_json(url)
  return M.request({ method = "GET", url = url, expect = "json" })
end

return M
