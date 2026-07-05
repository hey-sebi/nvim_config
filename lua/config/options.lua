-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- ---------------------------------------------
--  General settings
-- ---------------------------------------------

-- Explicitly set the order of "workspace detection" mechanisms. We usually
-- want this based on the working directory we start nvim in and not interfere
-- with GIT workspace detection (as it might then use submodules) or similar.
-- Alternative setting would be:
-- vim.g.root_spec = { { ".git", "lua" }, "cwd", "lsp" }
vim.g.root_spec = { "cwd" }

-- ---------------------------------------------
--  Windows specific settings
-- ---------------------------------------------
if vim.fn.has("win32") == 1 then
  -- Use PowerShell Core instead of cmd as shell
  vim.opt.shell = "pwsh.exe"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
  -- Neovide scaling
  vim.g.neovide_scale_factor = 1.0
  vim.o.guifont = "JetBrainsMono Nerd Font:h12"
end

-- Set LSP log level to warn to prevent huge log files
vim.lsp.set_log_level("warn")
