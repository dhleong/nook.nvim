local nio = require("nio")

---@param motion_type "line"|"char"|"block"
local function resolve_motion(motion_type)
  local start_line, start_col = unpack(vim.fn.getpos("'["), 2, 3)
  local end_line, end_col = unpack(vim.fn.getpos("']"), 2, 3)

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    return
  end

  if motion_type == "line" then
    start_col = 0
    end_col = vim.fn.strwidth(lines[#lines])
  else
    if start_col > 1 then
      lines[1] = string.sub(lines[1], start_col - 1)
    end
    if end_col > 1 then
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
  end

  return lines
end

local function require_config()
  local config = require("nook.adapter").get_config()
  if not config then
    error("[nook] No adapter configured for buffer")
  end
  return config
end

local Callables = {}

function Callables.connect()
  -- TODO: This should probably support user choice somehow

  local adapter = require("nook.adapter").get()
  if adapter then
    require("nio").run(function()
      adapter:connect()
      print("Connected.")
    end)
  end
end

---@param motion_type "line"|"char"|"block"
function Callables.eval_motion(motion_type)
  local lines = resolve_motion(motion_type)
  if lines then
    local s = table.concat(lines, "\n")
    local config = require_config()
    nio.run(function()
      print(require("nook.editor.replish").eval(config, s))
    end)
  end
end

---@param param vim.api.keyset.create_user_command.command_args
function Callables.last(param)
  local Last = require("nook.editor.last")
  Last.show({ focus = not param.bang })
end

function Callables.prepare_eval_motion()
  local config = require_config()
  nio.run(function()
    config.adapter:connect()
  end)

  vim.o.operatorfunc = "v:lua.require'nook.editor.callables'.eval_motion"
  vim.api.nvim_feedkeys("g@", "ni", false)
end

function Callables.prompt_eval()
  local config = require_config()
  nio.run(function()
    require("nook.editor.replish").prompt_eval(config)
  end)
end

return Callables
