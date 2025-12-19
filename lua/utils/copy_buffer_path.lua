local M = {}

local function notify(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "Path" })
end

local function get_root()
  local ok, util = pcall(require, "lazyvim.util")
  if ok and util.root and type(util.root.get) == "function" then
    local r = util.root.get()
    if r and r ~= "" then
      return r
    end
  end
  return (vim.uv or vim.loop).cwd()
end

local function to_rel(path)
  local root = get_root()
  -- make path relative to root (not just cwd)
  if root and root ~= "" then
    root = vim.fs.normalize(root)
    path = vim.fs.normalize(path)
    if path:sub(1, #root) == root then
      local rel = path:sub(#root + 2) -- +2 to drop path separator
      if rel ~= "" then
        return rel
      end
    end
  end
  return vim.fn.fnamemodify(path, ":.")
end

local function set_clipboard(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
end

function M.copy_buffer_abs()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    notify("Current buffer has no file path")
    return
  end
  set_clipboard(vim.fs.normalize(file))
  notify("Copied absolute path")
end

function M.copy_buffer_rel()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    notify("Current buffer has no file path")
    return
  end
  set_clipboard(to_rel(file))
  notify("Copied relative path")
end

return M
