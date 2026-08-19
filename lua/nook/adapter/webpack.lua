---@class WebpackAdapterOpts
---@field url string
---
---@class WebpackAdapter: WebpackAdapterOpts
---@field transport NookTransport?
local WebpackAdapter = {}

---@param args WebpackAdapterOpts
function WebpackAdapter:new(args)
  local o = vim.tbl_deep_extend("force", {}, args or {})

  setmetatable(o, self)
  self.__index = self

  return o
end

function WebpackAdapter:connect()
  if self.transport then
    -- TODO: validate
    return self.transport
  end

  local params = { url = self.url }

  local transport = require("nook.transport").find_first(params, {
    "chrome_remote_debugging",
    "applescript_browser_js",
  })

  if transport then
    self.transport = transport
    return transport
  else
    error("No transport")
  end
end

function WebpackAdapter:destroy()
  local transport = self.transport
  if transport then
    self.transport:destroy()
  end
end

function WebpackAdapter:evaluate(ctx)
  local code
  local bufnr
  if type(ctx) == "string" then
    code = ctx
    bufnr = 0
  else
    code = ctx.code
    bufnr = ctx.bufnr
  end

  -- TODO: extract module better and add the code to look it up
  local module = vim.fn.bufname(bufnr)
  code = string.gsub(code, "$m", "get_module('" .. module .. "')")

  return self:connect():evaluate(code)
end

return WebpackAdapter
