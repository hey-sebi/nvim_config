local M = {}

local ls = require("luasnip")
-- Forward: expand current snippet or jump to next placeholder
function M.tab_replace()
  if ls.expand_or_locally_jumpable() then
    ls.expand_or_jump()
  else
    -- fall back to a real <Tab> if not in a snippet
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, true, true), "n", false)
  end
end

-- Backward: jump to previous placeholder
function M.shift_tab_replace()
  if ls.jumpable(-1) then
    ls.jump(-1)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, true, true), "n", false)
  end
end

function M.expand_or_jump()
  if ls.expand_or_locally_jumpable() then
    ls.expand_or_jump()
  end
end

function M.jump_if_jumpable()
  if ls.jumpable(-1) then
    ls.jump(-1)
  end
end

return M
