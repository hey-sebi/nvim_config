local M = {}

---Remove trailing whitespace in the current buffer.
---Equivalent to :%s/\s\+$//e
function M.trim_trailing_whitespace()
  vim.cmd([[keepjumps keeppatterns %s/\s\+$//e]])
end

return M
