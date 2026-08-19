local module_helper_script = [[
(() => {
window.__nook_get_module__ = (module) => {
  const {wpreq} = window.__nook_get_module__;
  return wpreq(module);
};
const webpackKey = Object.keys(window)
  .filter((k) => k.startsWith("webpackChunk"))[0]
if (webpackKey == null) throw new Error("webpackChunk not found");
window[webpackKey].push([[Symbol('repl')], {}, (r) => (window.__nook_get_module__.wpreq = r)]);
return JSON.stringify({status: 'success', result: 'true'});
})()
]]

---@class WebpackAdapterOpts
---@field url string
---
---@class WebpackAdapter: WebpackAdapterOpts
---@field transport NookTransport?
local WebpackAdapter = {}

---@param args WebpackAdapterOpts
function WebpackAdapter:new(args)
  local o = vim.tbl_deep_extend("force", {
    name = "WebpackAdapter",
  }, args or {})

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

  local transport = require("nook.transport").find_first({
    require("nook.transport.chrome_remote_debugging"):new(params),
    require("nook.transport.applescript_browser_js"):new(params),
  })

  self.transport = transport
  transport:evaluate({ code = module_helper_script, raw = true })
end

function WebpackAdapter:destroy()
  local transport = self.transport
  if transport then
    self.transport:destroy()
  end
end

function WebpackAdapter:evaluate(ctx)
  local request = require("nook.adapter.core").normalize(ctx)
  if string.find(request.code, "$m") then
    error("Module code evaluation not yet supported")
  end

  -- TODO: extract module better and add the code to look it up
  local module = vim.fn.bufname(request.bufnr)
  request.code = string.gsub(request.code, "$m", "__nook_get_module__('" .. module .. "')")

  return self:connect():evaluate(request.code)
end

return WebpackAdapter
