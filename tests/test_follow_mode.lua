-- Regression test script for follow_mode module using fs_event
local uv = vim.uv or vim.loop
local fs = vim.fs

-- Get path to config root
local script_path = debug.getinfo(1).source:sub(2)
local test_dir = vim.fn.fnamemodify(script_path, ":p:h")
local config_root = vim.fn.fnamemodify(test_dir, ":h")

-- Add lua path and load module
package.path = package.path .. ";" .. fs.normalize(config_root .. "/lua/?.lua")
local follow_mode = require("utils.follow_mode")

print("Starting follow_mode tests...")

-- 1. Create temporary log file
local tmp_path = fs.normalize(vim.fn.tempname() .. "_follow_test.log")
local fd = assert(uv.fs_open(tmp_path, "w", 438))
uv.fs_write(fd, "line 1\nline 2\n")
uv.fs_close(fd)

-- 2. Open file in Neovim buffer
vim.cmd("edit " .. vim.fn.fnameescape(tmp_path))
local bufnr = vim.api.nvim_get_current_buf()

assert(vim.api.nvim_buf_is_valid(bufnr), "Buffer should be valid")
assert(not follow_mode.is_enabled(bufnr), "Follow mode should initially be disabled")

-- 3. Enable follow mode
follow_mode.enable(bufnr)
assert(follow_mode.is_enabled(bufnr), "Follow mode should be enabled")

-- Verify cursor jumped to EOF
local cursor_line_init = vim.api.nvim_win_get_cursor(0)[1]
assert(cursor_line_init == 2, "Cursor should jump to line 2 (EOF), got " .. tostring(cursor_line_init))
print("PASS: follow_mode enable and initial EOF jump")

-- 4. Append to file on disk to trigger fs_event
local fd_app = assert(uv.fs_open(tmp_path, "a", 438))
uv.fs_write(fd_app, "line 3\nline 4\n")
uv.fs_close(fd_app)

-- Wait for fs_event and debouncer to update buffer
local success = vim.wait(2000, function()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return #lines >= 4
end, 50)

assert(success, "Buffer should reload external changes via fs_event")

local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
assert(#lines == 4 and lines[4] == "line 4", "Buffer content mismatch: " .. vim.inspect(lines))

local cursor_line_after = vim.api.nvim_win_get_cursor(0)[1]
assert(cursor_line_after == 4, "Cursor should follow to line 4 (EOF), got " .. tostring(cursor_line_after))
print("PASS: fs_event detection, buffer reload and follow to EOF")

-- 5. Disable follow mode
follow_mode.disable(bufnr)
assert(not follow_mode.is_enabled(bufnr), "Follow mode should be disabled")
print("PASS: follow_mode disable")

-- Clean up temporary file
uv.fs_unlink(tmp_path)

print("All follow_mode tests passed successfully!")
