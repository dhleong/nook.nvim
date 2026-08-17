local M = {}

---@param opts? NookConfig
function M.setup(opts)
  require("nook.config").setup(opts)
  require("nook.editor").setup()
end

return M
