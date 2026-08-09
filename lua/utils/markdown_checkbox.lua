local M = {}

--- Toggle a checkbox on a single line string.
--- Handles:
---   "- [ ] text" -> "- [x] text"
---   "- [x] text" -> "- [ ] text"
---   "- text"     -> "- [ ] text"
---   "text"       -> "- [ ] text"
---   ""           -> "- [ ] "
function M.toggle_line(line)
  local indent, pre, status, rest = line:match("^(%s*)(.-)(%[%s*[xX%s]%s*%])%s*(.*)")
  if status and (pre == "" or pre:match("^[%*%+%-]%s+$") or pre:match("^%d+%.%s+$")) then
    local new_status = status:find("[xX]") and "[ ]" or "[x]"
    local bullet = (pre == "" and "- " or pre)
    return indent .. bullet .. new_status .. (rest ~= "" and (" " .. rest) or "")
  end

  local indent2, bullet2, rest2 = line:match("^(%s*)([%*%+%-]%s+)(.*)")
  if not indent2 then
    indent2, bullet2, rest2 = line:match("^(%s*)(%d+%.%s+)(.*)")
  end
  if indent2 then
    return indent2 .. bullet2 .. "[ ] " .. rest2
  end

  if line:match("^%s*$") then
    return "- [ ] "
  end

  local indent3, text3 = line:match("^(%s*)(.*)")
  return indent3 .. "- [ ] " .. text3
end

--- Insert / create a checkbox on a single line string.
function M.create_line(line)
  local indent, pre, status, rest = line:match("^(%s*)(.-)(%[%s*[xX%s]%s*%])%s*(.*)")
  if status and (pre == "" or pre:match("^[%*%+%-]%s+$") or pre:match("^%d+%.%s+$")) then
    return line
  end

  local indent2, bullet2, rest2 = line:match("^(%s*)([%*%+%-]%s+)(.*)")
  if not indent2 then
    indent2, bullet2, rest2 = line:match("^(%s*)(%d+%.%s+)(.*)")
  end
  if indent2 then
    return indent2 .. bullet2 .. "[ ] " .. rest2
  end

  if line:match("^%s*$") then
    return "- [ ] "
  end

  local indent3, text3 = line:match("^(%s*)(.*)")
  return indent3 .. "- [ ] " .. text3
end

--- Toggle checkbox on current line or visual selection
function M.toggle_checkbox()
  local mode = vim.api.nvim_get_mode().mode
  if mode:find("[vV\22]") then
    local lstart = vim.fn.line("v")
    local lend = vim.fn.line(".")
    if lstart > lend then
      lstart, lend = lend, lstart
    end

    local lines = vim.api.nvim_buf_get_lines(0, lstart - 1, lend, false)
    for i, l in ipairs(lines) do
      lines[i] = M.toggle_line(l)
    end
    vim.api.nvim_buf_set_lines(0, lstart - 1, lend, false, lines)
  else
    local line = vim.api.nvim_get_current_line()
    local new_line = M.toggle_line(line)
    vim.api.nvim_set_current_line(new_line)
  end
end

--- Create checkbox on current line or visual selection,
--- adding a new line at end of file if needed, and entering insert mode.
function M.create_checkbox()
  local mode = vim.api.nvim_get_mode().mode
  if mode:find("[vV\22]") then
    local lstart = vim.fn.line("v")
    local lend = vim.fn.line(".")
    if lstart > lend then
      lstart, lend = lend, lstart
    end

    local lines = vim.api.nvim_buf_get_lines(0, lstart - 1, lend, false)
    for i, l in ipairs(lines) do
      lines[i] = M.create_line(l)
    end
    vim.api.nvim_buf_set_lines(0, lstart - 1, lend, false, lines)
    vim.cmd("startinsert!")
  else
    local curr_line = vim.fn.line(".")
    local total_lines = vim.api.nvim_buf_line_count(0)
    local line_content = vim.api.nvim_get_current_line()

    if curr_line == total_lines and line_content:match("%S") then
      -- At end of file on a non-empty line: append new line with checkbox
      vim.api.nvim_buf_set_lines(0, total_lines, total_lines, false, { "- [ ] " })
      vim.api.nvim_win_set_cursor(0, { total_lines + 1, 6 })
    else
      local new_line = M.create_line(line_content)
      vim.api.nvim_set_current_line(new_line)
      if line_content:match("^%s*$") then
        vim.api.nvim_win_set_cursor(0, { curr_line, #new_line })
      end
    end

    -- Enter insert mode at the end of the line
    vim.cmd("startinsert!")
  end
end

return M
