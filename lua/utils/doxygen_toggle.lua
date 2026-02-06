local M = {}

local function get_lines(bufnr, srow, erow)
  if not srow or not erow then
    return {}
  end
  if srow > erow then
    srow, erow = erow, srow
  end
  -- nvim_buf_get_lines uses 0-based, end-exclusive
  return vim.api.nvim_buf_get_lines(bufnr, srow, erow + 1, false)
end

local function set_lines(bufnr, srow, erow, new_lines)
  if not srow or not erow then
    return
  end
  if srow > erow then
    srow, erow = erow, srow
  end
  vim.api.nvim_buf_set_lines(bufnr, srow, erow + 1, false, new_lines)
end

local function leading_ws(line)
  return (line:match("^(%s*)") or "")
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function is_doxygen_block(lines)
  if #lines < 2 then
    return false
  end
  local first, last = lines[1], lines[#lines]
  if not first or not last then
    return false
  end
  return first:find("/%*%*") ~= nil and last:find("%*/") ~= nil
end

local function is_triple_slash_run(lines)
  if #lines < 1 then
    return false
  end
  for _, l in ipairs(lines) do
    if not l:match("^%s*///") then
      return false
    end
  end
  return true
end

local function block_to_slashes(lines)
  local indent = leading_ws(lines[1] or "")
  local out = {}

  -- Interior lines: 2..#-1
  for i = 2, #lines - 1 do
    local l = lines[i] or ""
    local inner = l:gsub("^%s*", "") -- strip leading ws
    inner = inner:gsub("^%*%s?", "") -- strip leading '*' and one optional space

    if inner == "" then
      table.insert(out, indent .. "///")
    else
      table.insert(out, indent .. "/// " .. inner)
    end
  end

  if #out == 0 then
    out = { indent .. "///" }
  end
  return out
end

local function slashes_to_block(lines)
  local indent = leading_ws(lines[1] or "")
  local out = { indent .. "/**" }

  for _, l in ipairs(lines) do
    local content = l:gsub("^%s*///", "")
    content = content:gsub("^%s?", "") -- drop single leading space if present

    if content == "" then
      table.insert(out, indent .. " *")
    else
      table.insert(out, indent .. " * " .. content)
    end
  end

  table.insert(out, indent .. " */")
  return out
end

-- Always use marks, never vim.fn.mode() guessing
local function get_mark_range()
  local bufnr = vim.api.nvim_get_current_buf()
  local s = vim.api.nvim_buf_get_mark(bufnr, "<")
  local e = vim.api.nvim_buf_get_mark(bufnr, ">")
  -- marks are (row, col) 1-based rows
  local srow, erow = (s[1] or 0) - 1, (e[1] or 0) - 1
  if srow < 0 or erow < 0 then
    return nil
  end
  if srow > erow then
    srow, erow = erow, srow
  end
  return srow, erow
end

local function find_triple_slash_run(lines, row)
  if not lines[row + 1] or not lines[row + 1]:match("^%s*///") then
    return nil
  end

  local s = row
  while s > 0 and lines[s]:match("^%s*///") do
    s = s - 1
  end
  if not (lines[s + 1] and lines[s + 1]:match("^%s*///")) then
    return nil
  end

  local e = row
  while e < (#lines - 1) and lines[e + 2] and lines[e + 2]:match("^%s*///") do
    e = e + 1
  end

  return s, e
end

local function find_doxygen_block(lines, row, max_scan)
  max_scan = max_scan or 200

  local start_row = nil
  local i = row
  local scanned = 0
  while i >= 0 and scanned <= max_scan do
    if lines[i + 1] and lines[i + 1]:find("/%*%*") then
      start_row = i
      break
    end
    i = i - 1
    scanned = scanned + 1
  end
  if not start_row then
    return nil
  end

  local end_row = nil
  i = start_row
  scanned = 0
  while i < #lines and scanned <= max_scan do
    if lines[i + 1] and lines[i + 1]:find("%*/") then
      end_row = i
      break
    end
    i = i + 1
    scanned = scanned + 1
  end
  if not end_row then
    return nil
  end

  -- Cursor must be inside the found region
  if row < start_row or row > end_row then
    return nil
  end

  return start_row, end_row
end

function M.toggle_range(srow, erow)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = get_lines(bufnr, srow, erow)
  if #lines == 0 then
    return
  end

  if is_doxygen_block(lines) then
    set_lines(bufnr, srow, erow, block_to_slashes(lines))
    return
  end

  if is_triple_slash_run(lines) then
    set_lines(bufnr, srow, erow, slashes_to_block(lines))
    return
  end

  -- If selection is neither "pure", do nothing (safer than guessing).
end

function M.toggle_visual()
  local r = { get_mark_range() }
  if #r ~= 2 or not r[1] then
    return
  end
  M.toggle_range(r[1], r[2])
end

function M.toggle()
  local bufnr = vim.api.nvim_get_current_buf()
  local all = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1

  -- Prefer /// run if on /// line
  local s, e = find_triple_slash_run(all, row)
  if s and e then
    M.toggle_range(s, e)
    return
  end

  -- Otherwise try /** ... */ block around cursor
  s, e = find_doxygen_block(all, row)
  if s and e then
    M.toggle_range(s, e)
    return
  end
end

return M
