---@meta
---@module "path_utils"
--- Utilities for extracting, formatting, and copying Neovim buffer paths.
local M = {}

--- Triggers a standardized Neovim notification styled for path operations.
---@param msg string The message string to display in the notification body.
local function notify(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "Path" })
end

--- Attempts to discover the project root directory using LazyVim's root utility,
--- falling back to the current working directory (CWD) if unavailable.
---@return string|nil path The absolute path to the project root or CWD, or nil if lookup fails.
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

--- Converts an absolute file path into a relative path based on the project root.
--- Falls back to a standard CWD-relative format if outside the root tree.
---@param path string The absolute file path to be transformed.
---@return string rel_path The resolved path relative to the calculated project root.
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

--- Writes a string to both the system clipboard (`+`) and the unnamed register (`"`).
---@param text string The string content to set into the registers.
local function set_clipboard(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
end

--- Copies the current buffer's normalized absolute path to the system clipboard.
--- Warns the user via notification if the buffer has no valid path.
function M.copy_buffer_abs()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    notify("Current buffer has no file path")
    return
  end
  set_clipboard(vim.fs.normalize(file))
  notify("Copied absolute path")
end

--- Copies the current buffer's root-relative path to the system clipboard.
--- Warns the user via notification if the buffer has no valid path.
function M.copy_buffer_rel()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    notify("Current buffer has no file path")
    return
  end
  set_clipboard(to_rel(file))
  notify("Copied relative path")
end

--- Displays the current buffer's root-relative path via a Neovim notification banner (e.g., Noice).
--- Does not mutate clipboard state. Warns if the buffer has no valid path.
function M.show_buffer_rel()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    notify("Current buffer has no file path")
    return
  end
  notify(to_rel(file))
end

return M
