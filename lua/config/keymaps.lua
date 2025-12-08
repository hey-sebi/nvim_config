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
--  Unset predefined keybindings that I don't
--  use or want to use for other purposes
-- ---------------------------------------------

-- defaults to "save buffer"
vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<Nop>")

-- ---------------------------------------------
--  Code editing
-- ---------------------------------------------
-- Move selected lines in visual mode and reindent
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- ---------------------------------------------
--  Quality of life
-- ---------------------------------------------
-- Recenter after C-d or C-u
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Recenter after moving to next or previous search result
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste without losing the paste buffer content
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Reindent paragraph and then return to the same line we started in.
-- Uses the mark 't'
vim.keymap.set("n", "=ap", "mt=ap't")

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
local lsc = require("utils.luasnip_customization")

-- Forward: expand current snippet or jump to next placeholder
vim.keymap.set({ "i", "s" }, "<Tab>", lsc.tab_replace, { silent = true })
-- Backward: jump to previous placeholder
vim.keymap.set({ "i", "s" }, "<S-Tab>", lsc.shift_tab_replace, { silent = true })

-- Optional alternative keys
vim.keymap.set({ "i", "s" }, "<C-n>", lsc.expand_or_jump, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-p>", lsc.jump_if_jumpable, { silent = true })

-- ---------------------------------------------------------------------------
--  C++: Switch between header and implementation
-- ---------------------------------------------------------------------------

local cpp_switch = require("utils.cpp_switch")
vim.keymap.set("n", "<leader>fa", cpp_switch.switch_source_header_smart, { desc = "Switch between header/source" })
vim.keymap.set(
  "n",
  "<leader>fA",
  cpp_switch.switch_source_header_vsplit,
  { desc = "Switch header/source in vertical split" }
)

-- ---------------------------------------------------------------------------
--  Yanky customization
-- ---------------------------------------------------------------------------

vim.keymap.set("n", "<c-p>", "<Plug>(YankyPreviousEntry)")
vim.keymap.set("n", "<c-n>", "<Plug>(YankyNextEntry)")
