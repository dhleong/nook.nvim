local nio = require("nio")
local M = {}

---@param bufnr? number
function M.setup_buffer(bufnr)
  local b = bufnr or 0
  local config = require("nook.adapter").config_for_bufnr(b)
  if not config then
    return
  end

  local function nook_connect()
    -- TODO: This should probably support user choice somehow
    local adapter = require("nook.adapter").get()
    if adapter then
      require("nio").run(function()
        adapter:connect()
        print("Connected.")
      end)
    end
  end
  vim.api.nvim_buf_create_user_command(b, "NookConnect", nook_connect, {
    desc = "Connect Nook",
  })

  vim.keymap.set(
    "n",
    "cqp",
    nio.create(function()
      require("nook.editor.replish").prompt_eval(config)
    end),
    {
      buf = b,
      desc = "Open the nook replish",
    }
  )

  vim.keymap.set("n", "cqc", "cqp<c-f>i", {
    remap = true,
    desc = "Open the nook replish cmd window",
  })
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
