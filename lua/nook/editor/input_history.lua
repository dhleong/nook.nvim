local InputHistory = {
  ---@type string[]|nil
  _saved = nil,
}

function InputHistory._get_active()
  local old = {}
  local limit = vim.fn.histnr("@")
  if limit > 0 then
    for i = 1, limit do
      table.insert(old, vim.fn.histget("@", i))
    end
  end
  return old
end

function InputHistory._set_active(entries)
  vim.fn.histdel("@")

  for _, entry in ipairs(entries) do
    vim.fn.histadd("@", entry)
  end
end

function InputHistory.make_active(entries)
  InputHistory.save()
  InputHistory._set_active(entries)
end

function InputHistory.save()
  if not InputHistory._saved then
    InputHistory._saved = InputHistory._get_active()
  end
end

function InputHistory.restore()
  if InputHistory._saved then
    InputHistory._set_active(InputHistory._saved)
    InputHistory._saved = nil
  end
end

return InputHistory
