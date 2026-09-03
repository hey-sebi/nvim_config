--- Opens the file, hunk, submodule, or commit under the cursor from the Neogit status buffer.
--- Unlike Neogit's default `GoToFile` action, this keeps Neogit open in its split window
--- and opens the target file in the previous or adjacent editor split.
---
--- Behavior:
--- - If the cursor is on a diff hunk, computes the disk row offset and positions the cursor there.
--- - Targets the previous window (`#`), or the first non-floating, non-Neogit window in the tab.
--- - If no other editor window exists, creates a vertical split to the left (`leftabove vsplit`).
--- - Delegates submodules to `neogit.open` and commit refs to `commit_view`.
local function goto_file_preserve_split()
  local status = require("neogit.buffers.status").instance()
  if not status or not status.buffer then
    return
  end

  local item = status.buffer.ui:get_item_under_cursor()
  if not item then
    local ref = status.buffer.ui:get_yankable_under_cursor()
    if ref then
      require("neogit.buffers.commit_view").new(ref):open()
    end
    return
  end

  -- Submodules: open neogit in the submodule
  if item.absolute_path and status:has_submodule(item.absolute_path) then
    require("neogit").open({ cwd = item.absolute_path })
    return
  end

  -- File or hunk
  if item.absolute_path then
    -- Calculate target line number if cursor is on a diff hunk
    local target_row = nil
    if rawget(item, "diff") and item.diff.hunks then
      local line = status.buffer:cursor_line()
      local jump = require("neogit.lib.jump")
      for _, hunk in ipairs(item.diff.hunks) do
        if line >= hunk.first and line <= hunk.last then
          local offset = line - hunk.first
          target_row = jump.adjust_row(hunk.disk_from, offset, hunk.lines, "-")
          break
        end
      end
    end

    local cur_win = vim.api.nvim_get_current_win()
    local target_win = nil

    -- 1. Try the previous window (#)
    local prev_win_nr = vim.fn.winnr("#")
    if prev_win_nr > 0 then
      local prev_win_id = vim.fn.win_getid(prev_win_nr)
      if vim.api.nvim_win_is_valid(prev_win_id) and prev_win_id ~= cur_win then
        local cfg = vim.api.nvim_win_get_config(prev_win_id)
        if not cfg.relative or cfg.relative == "" then
          local buf = vim.api.nvim_win_get_buf(prev_win_id)
          local ft = vim.bo[buf].filetype
          if not vim.startswith(ft, "Neogit") then
            target_win = prev_win_id
          end
        end
      end
    end

    -- 2. Fallback: look for any valid non-floating, non-Neogit window in the current tab
    if not target_win then
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if win ~= cur_win and vim.api.nvim_win_is_valid(win) then
          local cfg = vim.api.nvim_win_get_config(win)
          if not cfg.relative or cfg.relative == "" then
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype
            if not vim.startswith(ft, "Neogit") then
              target_win = win
              break
            end
          end
        end
      end
    end

    -- 3. If no existing split window is found, open a vertical split to the left
    if not target_win then
      vim.cmd("leftabove vsplit")
      target_win = vim.api.nvim_get_current_win()
    end

    -- Switch focus to target window and open the file
    vim.api.nvim_set_current_win(target_win)
    vim.cmd("edit " .. vim.fn.fnameescape(item.absolute_path))
    if target_row then
      pcall(vim.api.nvim_win_set_cursor, target_win, { math.max(target_row, 1), 0 })
      vim.cmd("normal! zz")
    end
    return
  end

  local ref = status.buffer.ui:get_yankable_under_cursor()
  if ref then
    require("neogit.buffers.commit_view").new(ref):open()
  end
end

return {
  "NeogitOrg/neogit",
  opts = {
    mappings = {
      status = {
        -- NOTE: this must be lowercase <cr> because that is how it's setup in neogit
        ["<cr>"] = goto_file_preserve_split,
      },
    },
  },
}
