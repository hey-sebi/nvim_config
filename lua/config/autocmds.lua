-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- -----------------------------------------------------------------
--  Things to do when saving a buffer
-- -----------------------------------------------------------------

-- whitespace cleanup
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- -----------------------------------------------------------------
--  Adjust formatoptions for all buffers
-- -----------------------------------------------------------------

local formatoptions_group = vim.api.nvim_create_augroup("my_formatoptions", { clear = true })

-- General formatoptions behavior
vim.api.nvim_create_autocmd("FileType", {
  group = formatoptions_group,
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

-- Create an autocommand group for VS Code specific tweaks
local vscode_group = vim.api.nvim_create_augroup("VSCodeTweak", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = vscode_group,
  -- List of file types where we don't want spell checking:
  pattern = { "log", "proto", "text", "cpp", "cdl", "groovy" },
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- Enable text wrapping for Markdown files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.textwidth = 100 -- standard column wrap
    vim.opt_local.formatoptions:append("t") -- auto-wrap text using textwidth
  end,
})

-- Log file location jump map (gd)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "log",
  callback = function(event)
    vim.keymap.set("n", "gd", function()
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2] + 1

      -- Matches: filename:linenumber
      local pattern = "([%w_%.%-%/%\\]+):(%d+)"
      local file, lnum
      local start_idx = 1
      while true do
        local s, e, f, l = line:find(pattern, start_idx)
        if not s then break end
        if col >= s and col <= e then
          file = f
          lnum = tonumber(l)
          break
        end
        start_idx = e + 1
      end

      -- Fallback: if cursor is not directly on a match, check if there is exactly one match in the line
      if not file then
        start_idx = 1
        local first_file, first_lnum
        local count = 0
        while true do
          local s, e, f, l = line:find(pattern, start_idx)
          if not s then break end
          first_file = f
          first_lnum = tonumber(l)
          count = count + 1
          start_idx = e + 1
        end
        if count == 1 then
          file = first_file
          lnum = first_lnum
        end
      end

      if not file or not lnum then
        vim.notify("No filename:linenumber found on this line", vim.log.levels.WARN)
        return
      end

      local basename = vim.fn.fnamemodify(file, ":t")
      local root = vim.fs.root(0, { ".git", ".neoconf.json" }) or vim.uv.cwd()
      local matches = vim.fs.find(basename, {
        path = root,
        upward = false,
        type = "file",
        limit = 10,
      })

      if #matches == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(matches[1]))
        vim.api.nvim_win_set_cursor(0, { lnum, 0 })
        vim.cmd("normal! zz")
      elseif #matches > 1 then
        require("snacks").picker.select(matches, {
          prompt = "Select File (" .. basename .. ":" .. lnum .. ")",
          format_item = function(item)
            return vim.fn.fnamemodify(item, ":.")
          end,
        }, function(choice)
          if choice then
            vim.cmd("edit " .. vim.fn.fnameescape(choice))
            vim.schedule(function()
              pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 })
              vim.cmd("normal! zz")
            end)
          end
        end)
      else
        -- Fallback: open Snacks files picker prefilled with the basename
        require("snacks").picker.files({ search = basename })
      end
    end, { buffer = event.buf, desc = "Go to log source location" })
  end,
})
