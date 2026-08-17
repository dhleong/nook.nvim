local M = {}

function M.setup_buffer(bufnr)
  local b = bufnr or 0
  local config = require("nook.config").create_buffer_config(b)
  if not config then
    return
  end

  vim.keymap.set("n", "cqc", function()
    require("nook.editor.replish").activate(config)
  end, {
    buf = b,
    desc = "Open the nook replish",
  })
end

function M.try_setup_current_buffer()
  M.setup_buffer(vim.fn.bufnr("%"))
end

function M.setup()
  local augroup = vim.api.nvim_create_augroup("nook_autocmds", { clear = true })
  local enabled_filetypes = { "typescriptreact", "javascriptreact" }

  vim.api.nvim_create_autocmd({ "FileType" }, {
    group = augroup,
    pattern = enabled_filetypes,
    callback = M.try_setup_current_buffer(),
  })
  -- TODO: ?
  -- vim.api.nvim_create_autocmd({'BufEnter'}, {
  --   group = augroup,
  --   callback = M.try_setup_current_buffer()
  -- })
end

return M
