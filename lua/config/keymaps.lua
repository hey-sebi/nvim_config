-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- or: ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/keymaps.lua (-nix systems)
-- or: C:\Users\<YourUsername>\AppData\Local\nvim-data\lazy\LazyVim\lua\lazyvim\config\keymaps.lua
-- Add any additional keymaps here
-- Modes:
--   n:     normal mode
--   i:     insert mode
--   v:     visual mode
--   V:     visual line mode
--   <C-v>: visual block mode
--   x:     all visual modes

-- ---------------------------------------------
--  Files
-- ---------------------------------------------
vim.keymap.set({ "n", "x" }, "<leader>fs", "<cmd>w<cr>", { desc = "Save file" })
vim.keymap.set("n", "<leader>fo", ":e ", { desc = "Open file (Root Dir)", silent = false })
vim.keymap.set("n", "<leader>fO", ":e %:h/", { desc = "Open file (cwd)", silent = false })

-- ---------------------------------------------
--  List navigation
-- ---------------------------------------------

-- Navigate Quickfix list
vim.keymap.set("n", "<leader>jn", "<cmd>cn<CR>", { desc = "Quickfix Next" })
vim.keymap.set("n", "<leader>jp", "<cmd>cp<CR>", { desc = "Quickfix Prev" })
vim.keymap.set("n", "<leader>jo", "<cmd>copen<CR>", { desc = "Quickfix Open" })
vim.keymap.set("n", "<leader>jc", "<cmd>cclose<CR>", { desc = "Quickfix Close" })

-- Navigate Location list
vim.keymap.set("n", "<leader>ln", "<cmd>lnext<CR>", { desc = "Loclist Next" })
vim.keymap.set("n", "<leader>lp", "<cmd>lprev<CR>", { desc = "Loclist Prev" })
vim.keymap.set("n", "<leader>lo", "<cmd>lopen<CR>", { desc = "Loclist Open" })
vim.keymap.set("n", "<leader>lc", "<cmd>lclose<CR>", { desc = "Loclist Close" })

-- ---------------------------------------------
--  LuaSnip jumps
-- ---------------------------------------------
local ls = require("luasnip")

-- Forward: expand current snippet or jump to next placeholder
vim.keymap.set({ "i", "s" }, "<Tab>", function()
  if ls.expand_or_locally_jumpable() then
    ls.expand_or_jump()
  else
    -- fall back to a real <Tab> if not in a snippet
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, true, true), "n", false)
  end
end, { silent = true })

-- Backward: jump to previous placeholder
vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, true, true), "n", false)
  end
end, { silent = true })

-- Optional alternative keys
vim.keymap.set({ "i", "s" }, "<C-n>", function()
  if ls.expand_or_locally_jumpable() then
    ls.expand_or_jump()
  end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-p>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  end
end, { silent = true })
