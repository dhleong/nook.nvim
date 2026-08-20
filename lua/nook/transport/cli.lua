local nio = require("nio")

local strings = require("nook.util.strings")

---@class CliTransportOpts
---@field cmd string
---@field args? string[]
---@field cwd? string
---@field env? table
---@field skip_echoed_input? boolean
---@field is_prompt_line fun(line: string): boolean
---@field on_line? fun(line: string)
---@field on_start? fun(transport: CliTransport)

---@class CliTransport: CliTransportOpts
---@field _has_initial_prompt boolean
---@field _output_queue nio.control.Queue
---@field _buffer? string[]
---@field _channel_id? number
local CliTransport = {}

---@param opts CliTransportOpts
function CliTransport:new(opts)
  local o = vim.tbl_deep_extend("force", {
    _output_queue = nio.control.queue(10),
  }, opts)

  setmetatable(o, self)
  self.__index = self

  return o
end

function CliTransport:connect()
  if self._channel_id then
    self:destroy()
  end

  if vim.fn.executable(self.cmd) == 0 then
    return false
  end

  self._buffer = { "" }
  local cmd = vim.list_extend({ self.cmd }, self.args or {})
  vim.cmd([[-tabnew]])
  local job = vim.fn.jobstart(cmd, {
    term = true,
    stdin = "pipe",
    cwd = self.cwd,
    env = self.env,
    on_stdout = function(_, lines)
      if #lines == 1 and lines[1] == "" then
        -- TODO: Eof
        return
      end

      -- The first line "may be" (docs imply always is) partial;
      -- append it to the previous last line
      local last = #self._buffer
      self._buffer[last] = self._buffer[last] .. lines[1]
      if #lines > 1 then
        vim.list_extend(self._buffer, lines, 2)
      end

      local i = last
      while i <= #self._buffer do
        if self:_handle_line(self._buffer[i], { idx = i, is_complete = i < #self._buffer }) then
          i = 1
        else
          i = i + 1
        end
      end
    end,
    on_exit = function()
      -- TODO:
      print("on exit")
    end,
  })
  vim.cmd.hide()
  if job <= 0 then
    error("Failed to start CLI " .. self.cmd)
  end
  self._channel_id = job

  if self.on_start then
    self.on_start(self)
  end
  return true
end

function CliTransport:destroy()
  if not self._channel_id then
    return
  end
  vim.fn.jobstop(self._channel_id)
  self._channel_id = nil
end

function CliTransport:evaluate(input)
  local channel_id = self._channel_id
  if not channel_id then
    error("CliTransport not connected")
  end

  local request = require("nook.transport.core").normalize_evaluate(input)

  local wrote = vim.fn.chansend(channel_id, request.code .. "\r")
  if wrote == 0 then
    error("CliTransport failed to write")
  end

  return self._output_queue.get()
end

---@param line string
---@param ctx {idx: number, is_complete: boolean}
function CliTransport:_handle_line(line, ctx)
  if ctx.is_complete and self.on_line then
    self.on_line(line)
  end

  if self.is_prompt_line(line) then
    if not self._has_initial_prompt then
      self._has_initial_prompt = true
    else
      local start = 1
      if self.skip_echoed_input then
        start = 2
      end
      self:_emit_output(table.concat(self._buffer, "\n", start, ctx.idx - 1))
    end
    self._buffer = vim.list_slice(self._buffer, ctx.idx + 1)
    if #self._buffer == 0 then
      self._buffer = { "" }
    end
  end
end

---@param output string
function CliTransport:_emit_output(output)
  self._output_queue.put_nowait(strings.trim(output))
end

---@param cmd string|string[]
---@param args string[]|nil
---@return string, string[]|nil
function CliTransport.compose_args(cmd, args)
  ---@type any
  local cmd_string = cmd
  local cmd_args = args or {}
  if type(cmd) == "table" then
    cmd_string = cmd[1]
    cmd_args = vim.list_slice(cmd, 2)

    if type(args) == "table" then
      vim.list_extend(cmd_args, args)
    end
  end

  if #cmd_args == 0 then
    return cmd_string, nil
  end

  return cmd_string, cmd_args
end

return CliTransport
