-- This file runs after the default ftplugin/c.lua
-- and is the standard way to override filetype-specific settings.

-- s1:/*  -> Start block, offset subsequent lines by +1 space relative to the '/'
-- mb:*   -> Middle lines start with '*', 'b' ensures trailing space is protected
-- ex:*/  -> End block
-- Note: we use s1:/* to cover /** as well.
vim.opt_local.comments = "s1:/*,mb:*,ex:*/,:///,://"

-- Ensure indentation follows the 'comments' configuration
-- c1: Indent of comment lines after the start is 1 space
-- C1: Indent comment lines according to the middle part of 'comments'
vim.opt_local.cinoptions = "c1,C1"

-- smartindent can sometimes interfere with cindent in comments
vim.opt_local.smartindent = false

-- Ensure indentexpr is empty so Neovim uses cindent
vim.opt_local.indentexpr = ""

-- Set formatting behaviors
vim.opt_local.formatoptions:append("tcrqjn")
vim.opt_local.formatoptions:remove("o")

-- Set the line limit for comments
vim.opt_local.textwidth = 90
