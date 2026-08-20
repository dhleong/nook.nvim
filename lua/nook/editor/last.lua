local nio = require("nio")
local strings = require("nook.util.strings")

local M = {
  _bufnr = nil,
}

function M._get_bufnr()
  if nio.current_task() then
    nio.scheduler()
  end

  local existing = M._bufnr
  if existing and nio.api.nvim_buf_is_loaded(existing) then
    return existing
  end

  print("create new buffer")
  local bufnr = nio.api.nvim_create_buf(false, true)
  if bufnr == 0 then
    error("failed to create buffer")
  end

  -- The scratch buffer setting *should* set this,
  -- but just in case:
  vim.bo[bufnr].bufhidden = "hide"
  nio.api.nvim_buf_set_name(bufnr, "[nook] Last output")
  nio.api.nvim_buf_set_lines(bufnr, 0, 0, false, { "(no nook output yet)" })
  M._bufnr = bufnr
  return bufnr
end

---@param opts? {focus: boolean}
function M.show(opts)
  if nio.current_task() then
    nio.scheduler()
  end

  local bufnr = M._get_bufnr()
  vim.cmd.pedit("#" .. bufnr)

  -- This is a little jank; sometimes opening
  -- the buffer causes it to open... the wrong buffer?
  vim.cmd.wincmd("p")
  if vim.fn.bufnr("%") ~= bufnr then
    vim.cmd.buffer({ count = bufnr })
  end

  if not opts or not opts.focus then
    vim.cmd.wincmd("p")
  end
end

---@param config NookBufConfig
---@param output string
function M.update(config, output)
  local ft = vim.bo[config.bufnr].filetype
  local bufnr = M._get_bufnr()
  local lines = strings.split(output, "\n")

  print(vim.inspect(lines))
  nio.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].filetype = ft
end

return M
