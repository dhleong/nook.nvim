local mappings = require("nook.editor.mappings")

local M = {}

---@param bufnr? number
function M.setup_buffer(bufnr)
  local b = bufnr or 0
  local config = require("nook.adapter").config_for_bufnr(b)
  if not config then
    return
  end

  for _, command in ipairs(mappings.commands) do
    ---@type any, any
    local name, callable = unpack(command)
    vim.api.nvim_buf_create_user_command(b, name, callable, {
      bang = command.bang,
      desc = command.desc,
    })
  end

  for _, keymap in ipairs(mappings.keys) do
    ---@type any, any
    local lhs, rhs = unpack(keymap)
    local modes = keymap.mode or keymap.modes or "n"
    -- TODO: Some mappings are not "core" and maybe
    -- users prefer we don't set them?
    vim.keymap.set(modes, lhs, rhs, {
      remap = keymap.remap,
      desc = keymap.desc,
    })
  end
end

function M.try_setup_current_buffer()
  -- TODO: check configs
  -- M.setup_buffer(vim.fn.bufnr("%"))
end

function M.setup()
  local enabled_filetypes = vim.tbl_keys(require("nook.config").filetypes)

  local augroup = vim.api.nvim_create_augroup("nook_autocmds", { clear = true })

  vim.api.nvim_create_autocmd({ "FileType" }, {
    group = augroup,
    pattern = enabled_filetypes,
    callback = function()
      M.setup_buffer()
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = augroup,
    callback = function()
      M.try_setup_current_buffer()
    end,
  })
end

return M
