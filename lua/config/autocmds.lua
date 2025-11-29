-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
--
--

-- -----------------------------------------------------------------
--  Adjust formatoptions for all buffers
-- -----------------------------------------------------------------
local group = vim.api.nvim_create_augroup("my_formatoptions", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "*",
  callback = function()
    -- note: this is buffer-local, therefore this must be done this way
    vim.opt_local.formatoptions:remove({ "o" })
    -- formatoptions:
    -- l — long lines not automatically broken in non-comments
    -- n — recognize numbered lists (1., -, etc.)
    -- t — auto-wrap text using textwidth
    -- o — add comment leader on o/O
    -- r — continue comments on <Enter>
    -- c — auto-wrap comments
    -- q — allow gq formatting
    -- j — remove comment leader when joining lines
    -- Example for disabling multiple settings:
    -- vim.opt_local.formatoptions:remove({ "o", "r" })
  end,
})

-- -----------------------------------------------------------------
-- Jump to file locations shown in terminal output under cursor
-- -----------------------------------------------------------------
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(args)
    local buf = args.buf

    vim.keymap.set("n", "<leader>go", function()
      local word = vim.fn.expand("<cfile>")

      -- 1) MSVC style: path(lnum,col)
      local path, lnum, col = word:match("^(.-)%((%d+),(%d+)%)$")
      -- 2) MSVC style: path(lnum)
      if not path then
        path, lnum = word:match("^(.-)%((%d+)%)$")
      end
      -- 3) GCC/Clang style: path:lnum:col or path:lnum
      if not path then
        path, lnum, col = word:match("^(.-):(%d+):?(%d*)$")
      end

      if not path then
        if vim.fn.filereadable(word) == 1 then
          vim.cmd.edit(vim.fn.fnameescape(word))
        else
          vim.notify("No file under cursor", vim.log.levels.WARN)
        end
        return
      end

      if vim.fn.filereadable(path) == 0 then
        vim.notify("File not found: " .. path, vim.log.levels.WARN)
        return
      end

      vim.cmd.edit(vim.fn.fnameescape(path))

      local line = tonumber(lnum) or 1
      local colnum = tonumber(col or 1) or 1
      vim.api.nvim_win_set_cursor(0, { line, math.max(0, colnum - 1) })
    end, { buffer = buf, desc = "Open file:line(:col) under cursor" })
  end,
})
