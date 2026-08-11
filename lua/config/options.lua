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

-- Always keep 10 lines visible above/below cursor
vim.opt.scrolloff = 10

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

-- Always sync Neovim default yank/paste with the system clipboard register
vim.opt.clipboard = "unnamedplus"

-- Safe fallback loader for OSC 52
local function setup_osc52_clipboard()
  local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if not ok then
    return -- If using an older Neovim version or missing the module, fallback to default behavior
  end

  -- Safe paste handler: reads from Neovim's internal default register
  -- This prevents errors when a terminal emulator blocks remote clipboard reading for security reasons
  local function safe_paste()
    return {
      vim.fn.split(vim.fn.getreg('"'), "\n"),
      vim.fn.getregtype('"'),
    }
  end

  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = safe_paste,
      ["*"] = safe_paste,
    },
  }
end

-- Detect runtime environment dynamically
local is_remote_or_headless = vim.env.SSH_CONNECTION ~= nil
  or vim.env.SSH_TTY ~= nil
  or vim.env.TMUX ~= nil
  or vim.fn.has("gui_running") == 0

-- On headless/remote/SSH servers, force OSC 52 byte-streaming
-- On local desktop instances (Windows/Linux GUI), let Neovim auto-detect native APIs (win32yank, wl-copy, xclip)
if is_remote_or_headless and vim.fn.has("win32") == 0 then
  setup_osc52_clipboard()
end
