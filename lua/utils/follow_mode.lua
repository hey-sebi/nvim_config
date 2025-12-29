-- Buffer-local "follow file" mode, similar to `tail -f` / `less +F`.
-- When enabled for a buffer:
--   - periodically runs :checktime to reload external changes
--   - jumps to EOF (G) if the buffer is visible

local M = {}

-- check for file changes update interval
local DEFAULT_INTERVAL_MS = 750

local uv = vim.uv or vim.loop

-- timer handles keyed by bufnr
local timers = {}

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

local function stop_timer(bufnr)
  local t = timers[bufnr]
  timers[bufnr] = nil

  if t then
    pcall(function()
      t:stop()
      t:close()
    end)
  end
end

local function start_timer(bufnr, interval_ms)
  stop_timer(bufnr)

  local t = uv.new_timer()
  timers[bufnr] = t

  t:start(
    0,
    interval_ms,
    vim.schedule_wrap(function()
      -- buffer gone -> cleanup
      if not is_buf_valid(bufnr) then
        stop_timer(bufnr)
        return
      end

      -- disabled -> cleanup
      if vim.b[bufnr].follow_mode_enabled ~= true then
        stop_timer(bufnr)
        return
      end

      checktime_for_buf(bufnr)

      -- Only jump if the *current window* shows this buffer.
      -- This prevents "mysterious jumping" in other splits/tabs.
      jump_to_eof_if_current_win_shows_buf(bufnr)
    end)
  )
end

-- Ensure we clean up if the buffer is wiped out
local augroup = vim.api.nvim_create_augroup("FollowMode", { clear = false })
vim.api.nvim_create_autocmd("BufWipeout", {
  group = augroup,
  callback = function(args)
    stop_timer(args.buf)
  end,
})

function M.enable(bufnr, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  opts = opts or {}

  if not is_buf_valid(bufnr) then
    return
  end

  vim.b[bufnr].follow_mode_enabled = true
  vim.b[bufnr].follow_mode_interval_ms = opts.interval_ms or vim.b[bufnr].follow_mode_interval_ms or DEFAULT_INTERVAL_MS

  start_timer(bufnr, vim.b[bufnr].follow_mode_interval_ms)
  jump_to_eof_if_current_win_shows_buf(bufnr)
  notify(bufnr, true)
end

function M.disable(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not is_buf_valid(bufnr) then
    return
  end

  vim.b[bufnr].follow_mode_enabled = false
  stop_timer(bufnr)
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
