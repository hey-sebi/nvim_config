local M = {}

local overseer = require("overseer")
local snacks = require("snacks")

-- Tries to find the output window of the most recently executed
-- Overseer task. If found, maximizes (and focuses) it. Otherwise
-- shows notifications.
function M.maximize_last_task_output()
  -- 1) Get most recent tasks (most recent first)
  local tasks = overseer.list_tasks({ recent_first = true })
  if vim.tbl_isempty(tasks) then
    vim.notify("No Overseer tasks found", vim.log.levels.WARN)
    return
  end

  -- access most recently executed task
  local task = tasks[1]

  -- 2) Get the output buffer for that task
  local bufnr = task:get_bufnr()
  if not bufnr or bufnr == 0 then
    vim.notify("Last task has no output buffer", vim.log.levels.WARN)
    return
  end

  -- 3) Find a window currently showing that buffer
  local target_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      target_win = win
      break
    end
  end

  -- 4) If no window is showing it yet, open the output, then find the window
  if not target_win then
    -- respect Overseer’s strategy as much as possible, but ensure it’s visible
    task:open_output("split")

    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == bufnr then
        target_win = win
        break
      end
    end

    if not target_win then
      vim.notify("Could not locate task output window", vim.log.levels.WARN)
      return
    end
  end

  -- 5) Jump to that window and maximize it
  vim.api.nvim_set_current_win(target_win)

  snacks.zen.zoom()
  --snacks.toggle.zoom()
end

return M
