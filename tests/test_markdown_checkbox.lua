-- Unit test script for markdown_checkbox module
local fs = vim.fs

local script_path = debug.getinfo(1).source:sub(2)
local test_dir = vim.fn.fnamemodify(script_path, ":p:h")
local config_root = vim.fn.fnamemodify(test_dir, ":h")

package.path = package.path .. ";" .. fs.normalize(config_root .. "/lua/?.lua")
local mc = require("utils.markdown_checkbox")

print("Starting markdown_checkbox tests...")

-- Test single-line toggles
local toggle_tests = {
  { input = "- [ ] Task 1", expected = "- [x] Task 1" },
  { input = "- [x] Task 1", expected = "- [ ] Task 1" },
  { input = "- [X] Task 1", expected = "- [ ] Task 1" },
  { input = "  * [ ] Nested", expected = "  * [x] Nested" },
  { input = "  * [x] Nested", expected = "  * [ ] Nested" },
  { input = "1. [ ] Numbered", expected = "1. [x] Numbered" },
  { input = "1. [x] Numbered", expected = "1. [ ] Numbered" },
  { input = "- Plain list", expected = "- [ ] Plain list" },
  { input = "Plain text", expected = "- [ ] Plain text" },
  { input = "", expected = "- [ ] " },
}

for i, t in ipairs(toggle_tests) do
  local actual = mc.toggle_line(t.input)
  assert(actual == t.expected, string.format("Toggle test #%d failed. Input: '%s', Expected: '%s', Got: '%s'", i, t.input, t.expected, actual))
end
print("PASS: Single line toggle tests")

-- Test single-line creation
local create_tests = {
  { input = "", expected = "- [ ] " },
  { input = "Check usage of parts", expected = "- [ ] Check usage of parts" },
  { input = "- Check usage of parts", expected = "- [ ] Check usage of parts" },
  { input = "  * Item", expected = "  * [ ] Item" },
  { input = "- [ ] Already checked", expected = "- [ ] Already checked" },
  { input = "- [x] Already done", expected = "- [x] Already done" },
}

for i, t in ipairs(create_tests) do
  local actual = mc.create_line(t.input)
  assert(actual == t.expected, string.format("Create test #%d failed. Input: '%s', Expected: '%s', Got: '%s'", i, t.input, t.expected, actual))
end
print("PASS: Single line create tests")

-- Test buffer EOF behavior for create_checkbox
local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "# Title", "Existing text line" })
vim.api.nvim_win_set_cursor(0, { 2, 0 }) -- cursor on line 2 (last line, non-empty)

mc.create_checkbox()

local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
assert(#lines == 3, "Should append a new line when at non-empty EOF, got line count " .. #lines)
assert(lines[3] == "- [ ] ", "Appended line should be '- [ ] ', got '" .. lines[3] .. "'")

print("PASS: EOF new line creation and insert mode transition")

print("All markdown_checkbox tests passed successfully!")
