local M = {}

local active = false
local trace_group = nil
local last_time = 0

local ignored_filetypes = {
  [""] = true,
  ["snacks_notif"] = true,
  ["noice"] = true,
  ["snacks_picker_input"] = true,
  ["snacks_picker_list"] = true,
  ["snacks_picker_preview"] = true,
  ["snacks_win_backdrop"] = true,
  ["snacks_layout_box"] = true,
  ["blink-cmp-menu"] = true,
  ["notify"] = true,
}

local function log_event(ev_name, args)
  if not active then
    return
  end
  local buf_ft = args.buf and vim.api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].filetype or ""
  if ignored_filetypes[buf_ft] then
    return
  end

  local now = vim.uv.hrtime()
  local diff_ms = (now - last_time) / 1e6
  last_time = now

  local fname = args.file ~= "" and args.file or (args.buf and vim.api.nvim_buf_get_name(args.buf) or "")
  if fname == "" then
    return
  end

  local timestamp = os.date("%H:%M:%S") .. string.format(".%03d", math.floor((now / 1e6) % 1000))
  local msg = string.format("[%s] [TRACE +%8.2fms] %-14s ft:%-10s %s", timestamp, diff_ms, ev_name, buf_ft, fname)
  print(msg)
end

function M.enable()
  if active then
    return
  end
  active = true
  last_time = vim.uv.hrtime()
  trace_group = vim.api.nvim_create_augroup("DiagnosticTracer", { clear = true })

  local events = {
    "BufReadPre",
    "BufReadPost",
    "BufEnter",
    "BufWinEnter",
    "FileType",
    "CursorHold",
    "CursorMoved",
    "WinEnter",
    "BufWritePre",
    "BufWritePost",
  }
  for _, ev in ipairs(events) do
    vim.api.nvim_create_autocmd(ev, {
      group = trace_group,
      callback = function(args)
        log_event(ev, args)
      end,
    })
  end
  vim.notify("Event Tracer Enabled", vim.log.levels.INFO)
end

function M.disable()
  if not active then
    return
  end
  active = false
  if trace_group then
    vim.api.nvim_del_augroup_by_id(trace_group)
    trace_group = nil
  end
  vim.notify("Event Tracer Disabled", vim.log.levels.INFO)
end

function M.toggle()
  if active then
    M.disable()
  else
    M.enable()
  end
end

-- Create user commands
vim.api.nvim_create_user_command("TracerEnable", M.enable, { desc = "Enable Event Performance Tracer" })
vim.api.nvim_create_user_command("TracerDisable", M.disable, { desc = "Disable Event Performance Tracer" })
vim.api.nvim_create_user_command("TracerToggle", M.toggle, { desc = "Toggle Event Performance Tracer" })

return M
