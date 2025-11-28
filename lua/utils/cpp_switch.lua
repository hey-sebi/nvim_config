local M = {}

-- ---------------------------------------------------------------------------
-- Switch header/source
--
-- General concept here: Tries LSP based resolution for other file first. If
-- that fails, tries some manually defined patterns.
-- ---------------------------------------------------------------------------

-- pattern we use to match header<->cpp and header<->implheader files
local alt_patterns = {
  { from = "(.+)%.cpp$", to = { "%1.h", "%1.hpp", "%1.hh", "%1.hxx" } },
  { from = "(.+)%.cc$", to = { "%1.h", "%1.hpp", "%1.hh", "%1.hxx" } },
  { from = "(.+)%.cxx$", to = { "%1.h", "%1.hpp", "%1.hh", "%1.hxx" } },
  { from = "(.+)%.c$", to = { "%1.h" } },

  { from = "(.+)%.h$", to = { "%1.c", "%1.cpp", "%1.cc", "%1.cxx", "%1-impl.h" } },
  { from = "(.+)%.hpp$", to = { "%1.cpp", "%1.cc", "%1.cxx" } },
  { from = "(.+)%.hh$", to = { "%1.cpp", "%1.cc", "%1.cxx" } },
  { from = "(.+)%.hxx$", to = { "%1.cpp", "%1.cc", "%1.cxx" } },

  { from = "(.+)%-impl%.h$", to = { "%1.h", "%1.hpp", "%1.hh" } },
}

-- Find alternate file in same directory using our patterns
local function find_alternate_same_dir(bufname)
  if bufname == "" then
    return nil
  end

  local dir = vim.fn.fnamemodify(bufname, ":h")
  local fname = vim.fn.fnamemodify(bufname, ":t")

  for _, rule in ipairs(alt_patterns) do
    if fname:match(rule.from) then
      for _, to_pat in ipairs(rule.to) do
        local target_name = fname:gsub(rule.from, to_pat)
        local full = dir .. "/" .. target_name
        if vim.loop.fs_stat(full) then
          return full
        end
      end
    end
  end

  return nil
end

-- Jump to existing window showing `target`, or open in vsplit if not visible
local function jump_or_vsplit(target)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if name == target then
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  vim.cmd("vsplit " .. vim.fn.fnameescape(target))
end

-- Same-window smart switch (LSP first, then patterns)
function M.switch_source_header_smart()
  local before = vim.api.nvim_buf_get_name(0)
  local ok = pcall(vim.cmd, "ClangdSwitchSourceHeader")
  local after = vim.api.nvim_buf_get_name(0)

  if ok and after ~= "" and after ~= before then
    return -- clangd handled it
  end

  local alt = find_alternate_same_dir(before)
  if alt then
    vim.cmd.edit(vim.fn.fnameescape(alt))
  else
    vim.notify("No alternate file found for " .. vim.fn.fnamemodify(before, ":t"), vim.log.levels.INFO)
  end
end

-- Vsplit smart switch:
-- - use clangd to *discover* alternate
-- - keep current window's buffer
-- - jump to existing window or open vsplit
function M.switch_source_header_vsplit()
  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_get_current_buf()
  local before = vim.api.nvim_buf_get_name(cur_buf)

  -- Try clangd to figure out the alternate
  local ok = pcall(vim.cmd, "ClangdSwitchSourceHeader")
  local after_buf = vim.api.nvim_get_current_buf()
  local after = vim.api.nvim_buf_get_name(after_buf)

  if ok and after ~= "" and after ~= before then
    -- Restore original window + buffer
    vim.api.nvim_set_current_win(cur_win)
    vim.api.nvim_set_current_buf(cur_buf)

    -- Now jump or vsplit the clangd target
    jump_or_vsplit(after)
    return
  end

  -- clangd didn't help; restore original (just to be safe)
  vim.api.nvim_set_current_win(cur_win)
  vim.api.nvim_set_current_buf(cur_buf)

  local alt = find_alternate_same_dir(before)
  if alt then
    jump_or_vsplit(alt)
  else
    vim.notify("No alternate file found for " .. vim.fn.fnamemodify(before, ":t"), vim.log.levels.INFO)
  end
end

return M
