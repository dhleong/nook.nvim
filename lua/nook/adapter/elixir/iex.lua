---@class ElixirIexAdapter: ElixirIexAdapterOpts
---@field transport NookTransport?
local ElixirIexAdapter = {}

---@class ElixirIexAdapterOpts
ElixirIexAdapter.defaults = {
  iex = {
    cmd = "iex",
    args = {
      "--sname",
      function()
        return ElixirIexAdapter.random_session_name()
      end,
      "--remsh",
      function(ctx)
        return ElixirIexAdapter.service_address(ctx)
      end,
    },
  },
}

function ElixirIexAdapter.random_session_name()
  local suffix, _ = string.gsub(vim.fn.reltimestr(vim.fn.reltime()), "[.]", "_")
  return "nook_iex_" .. suffix
end

function ElixirIexAdapter.service_address(ctx)
  local mix = require("nook.util.path").find_parent_of(ctx.bufnr, "mix.exs")
  local root_dir_name = vim.fs.basename(mix)
  return root_dir_name .. "@localhost"
end

---@param args? ElixirIexAdapterOpts
function ElixirIexAdapter:new(args)
  local o = vim.tbl_deep_extend("force", {
    name = "ElixirIexAdapter",
  }, ElixirIexAdapter.defaults, args or {})

  setmetatable(o, self)
  self.__index = self

  return o
end

function ElixirIexAdapter:connect()
  if self.transport then
    -- TODO: validate
    return true
  end

  local CliTransport = require("nook.transport.cli")

  local cmd, args = CliTransport.compose_args(self.iex.cmd or "cmd", self.iex.args)
  self.transport = require("nook.transport").find_first({
    CliTransport:new({
      cmd = cmd,
      args = args,
      skip_echoed_input = true,
      is_prompt_line = function(line)
        return string.match(line, "iex%(.+%)%d+>") ~= nil
      end,
    }),
  })

  return self.transport ~= nil
end

function ElixirIexAdapter:destroy()
  local transport = self.transport
  if transport then
    self.transport:destroy()
    self.transport = nil
  end
end

function ElixirIexAdapter:evaluate(ctx)
  if not self:connect() then
    error("Not connected")
  end
  local request = require("nook.adapter.core").normalize(ctx)
  return self.transport:evaluate(request.code)
end

return ElixirIexAdapter
