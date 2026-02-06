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

local file_pick = require("utils.file_pickers")
local ctx = file_pick.ctx_lazyvim_snacks()
-- prefills the picker with a filename without file ending
vim.keymap.set("n", "<leader>fm", function()
  -- mnemonic: file matches
  file_pick.open_basename(ctx, { add_dot = false })
end, { desc = "Find files: basename" })

-- prefills the picker with a filename without file ending, current working dir
vim.keymap.set("n", "<leader>fM", function()
  -- true directory scoping via Snacks `cwd`
  file_pick.open_dir_scoped(ctx, { add_dot = false, force_cwd = true })
end, { desc = "Find files: basename (cwd=dir)" })

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
if not vim.g.vscode then
  local lsc = require("utils.luasnip_customization")

  -- Forward: expand current snippet or jump to next placeholder
  vim.keymap.set({ "i", "s" }, "<Tab>", lsc.tab_replace, { silent = true })
  -- Backward: jump to previous placeholder
  vim.keymap.set({ "i", "s" }, "<S-Tab>", lsc.shift_tab_replace, { silent = true })

  -- Optional alternative keys
  vim.keymap.set({ "i", "s" }, "<C-n>", lsc.expand_or_jump, { silent = true })
  vim.keymap.set({ "i", "s" }, "<C-p>", lsc.jump_if_jumpable, { silent = true })
end
-- ---------------------------------------------------------------------------
--  C++: Switch between header and implementation
-- ---------------------------------------------------------------------------
if not vim.g.vscode then
  local cpp_switch = require("utils.cpp_switch")
  vim.keymap.set("n", "<leader>fa", cpp_switch.switch_source_header_smart, { desc = "Switch between header/source" })
  vim.keymap.set(
    "n",
    "<leader>fA",
    cpp_switch.switch_source_header_vsplit,
    { desc = "Switch header/source in vertical split" }
  )
end
-- ---------------------------------------------------------------------------
--  Yanky customization
-- ---------------------------------------------------------------------------
vim.keymap.set("n", "<C-n>", "]y", { desc = "Yank ring next" })
vim.keymap.set("n", "<C-p>", "[y", { desc = "Yank ring previous" })

-- ---------------------------------------------------------------------------
--  Copy buffer paths
-- ---------------------------------------------------------------------------
local pathclip = require("utils.copy_buffer_path")

-- <leader>fp is already used by LazyVim ("Projects") :contentReference[oaicite:2]{index=2}
vim.keymap.set("n", "<leader>fpa", pathclip.copy_buffer_abs, { desc = "Copy Absolute Path (Buffer)" })
vim.keymap.set("n", "<leader>fpr", pathclip.copy_buffer_rel, { desc = "Copy Relative Path (Buffer)" })

-- ---------------------------------------------------------------------------
--  Text manipulation
-- ---------------------------------------------------------------------------

-- whitespaces
local text = require("utils.text")
vim.keymap.set("n", "<leader>ctw", function()
  text.trim_trailing_whitespace()
end, { desc = "Trim trailing whitespace" })

-- Doxygen: toggle block <-> /// comments
vim.keymap.set("n", "<leader>ctd", function()
  require("utils.doxygen_toggle").toggle()
end, { desc = "Toggle Doxygen comment style" })

vim.keymap.set("x", "<leader>ctd", function()
  require("utils.doxygen_toggle").toggle()
end, { desc = "Toggle Doxygen comment style (selection)" })

-- ---------------------------------------------------------------------------
--  File follow mode
-- ---------------------------------------------------------------------------
local follow_mode = require("utils.follow_mode")

vim.keymap.set("n", "<leader>bf", function()
  follow_mode.toggle(0)
end, { desc = "Toggle Follow Mode (buffer)" })

-- ---------------------------------------------------------------------------
--  Load VSCode keymaps if relevant
-- ---------------------------------------------------------------------------
if vim.g.vscode then
  require("config.vscode-keymaps")
end
