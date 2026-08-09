-- Buffer-local "follow file" mode, similar to `tail -f` / `less +F`.
-- When enabled for a buffer:
--   - uses OS file system events (vim.uv.fs_event) to detect file updates instantly
--   - runs :checktime to reload external changes
--   - jumps to EOF (G) if the buffer is visible in the current window

local M = {}

local uv = vim.uv or vim.loop

-- Active fs_event watchers keyed by bufnr
local watchers = {}
-- Active debounce timers keyed by bufnr
local debounce_timers = {}

local DEBOUNCE_MS = 50

local function is_buf_valid(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
end

local function is_buf_visible_in_current_win(bufnr)
  local curwin = vim.api.nvim_get_current_win()
  return vim.api.nvim_win_get_buf(curwin) == bufnr
end

local function jump_to_eof_if_current_win_shows_buf(bufnr)
  if is_buf_visible_in_current_win(bufnr) then
    vim.cmd("normal! G")
  end
end

local function checktime_for_buf(bufnr)
  if not is_buf_valid(bufnr) then
    return
  end

  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("silent! checktime")
  end)
end

local function notify(bufnr, enabled)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    name = "[No Name]"
  end
  local msg = ("Follow mode %s: %s"):format(enabled and "enabled" or "disabled", name)
  vim.notify(msg, vim.log.levels.INFO, { title = "Follow Mode" })
end

local function stop_watcher(bufnr)
  local dt = debounce_timers[bufnr]
  debounce_timers[bufnr] = nil
  if dt then
    pcall(function()
      dt:stop()
      if not dt:is_closing() then
        dt:close()
      end
    end)
  end

  local w = watchers[bufnr]
  watchers[bufnr] = nil

  if w then
    pcall(function()
      w:stop()
      if not w:is_closing() then
        w:close()
      end
    end)
  end
end

local function trigger_update(bufnr)
  if not is_buf_valid(bufnr) or vim.b[bufnr].follow_mode_enabled ~= true then
    stop_watcher(bufnr)
    return
  end

  checktime_for_buf(bufnr)
  jump_to_eof_if_current_win_shows_buf(bufnr)
end

local function schedule_update(bufnr)
  local dt = debounce_timers[bufnr]
  if not dt then
    dt = uv.new_timer()
    debounce_timers[bufnr] = dt
  else
    dt:stop()
  end

  dt:start(
    DEBOUNCE_MS,
    0,
    vim.schedule_wrap(function()
      trigger_update(bufnr)
    end)
  )
end

local function start_watcher(bufnr)
  stop_watcher(bufnr)

  local full_path = vim.api.nvim_buf_get_name(bufnr)
  if full_path == "" or not uv.fs_stat(full_path) then
    return
  end

  local w = uv.new_fs_event()
  watchers[bufnr] = w

  local ok, err = pcall(function()
    w:start(
      full_path,
      {},
      vim.schedule_wrap(function(fs_err, filename, events)
        if fs_err then
          stop_watcher(bufnr)
          return
        end

        if not is_buf_valid(bufnr) or vim.b[bufnr].follow_mode_enabled ~= true then
          stop_watcher(bufnr)
          return
        end

        if events and (events.change or events.rename) then
          schedule_update(bufnr)
        end
      end)
    )
  end)

  if not ok or err then
    stop_watcher(bufnr)
  end
end

-- Clean up when buffer is wiped out
local augroup = vim.api.nvim_create_augroup("FollowMode", { clear = false })
vim.api.nvim_create_autocmd("BufWipeout", {
  group = augroup,
  callback = function(args)
    stop_watcher(args.buf)
  end,
})

function M.enable(bufnr, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  opts = opts or {}

  if not is_buf_valid(bufnr) then
    return
  end

  vim.b[bufnr].follow_mode_enabled = true

  start_watcher(bufnr)
  jump_to_eof_if_current_win_shows_buf(bufnr)
  notify(bufnr, true)
end

function M.disable(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not is_buf_valid(bufnr) then
    return
  end

  vim.b[bufnr].follow_mode_enabled = false
  stop_watcher(bufnr)
  notify(bufnr, false)
end

function M.toggle(bufnr, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not is_buf_valid(bufnr) then
    return
  end

  if vim.b[bufnr].follow_mode_enabled == true then
    M.disable(bufnr)
  else
    M.enable(bufnr, opts)
  end
end

function M.is_enabled(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return is_buf_valid(bufnr) and vim.b[bufnr].follow_mode_enabled == true
end

return M

