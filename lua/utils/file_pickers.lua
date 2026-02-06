local M = {}

---@class PrefillCtx
---@field get_fullpath fun():string
---@field open fun(query:string, opts?:{cwd?:string})
---@field relpath fun(fullpath:string):string|nil  -- optional; only needed for VSCode-style prefixing

local function split_parts(fullpath)
  -- :t:r => basename w/o ext, :h => directory
  local base = vim.fn.fnamemodify(fullpath, ":t:r")
  local dir_abs = vim.fn.fnamemodify(fullpath, ":p:h")
  return base, dir_abs
end

local function query_basename(fullpath, add_dot)
  local base = vim.fn.fnamemodify(fullpath, ":t:r")
  return add_dot and (base .. ".") or base
end

local function query_dir_prefixed(ctx, fullpath, add_dot)
  -- Use relpath if provided (VSCode approximation), else fall back to absolute dir prefix
  local rel = ctx.relpath and ctx.relpath(fullpath) or nil
  local dir = rel and vim.fn.fnamemodify(rel, ":h") or vim.fn.fnamemodify(fullpath, ":h")
  local base = vim.fn.fnamemodify(fullpath, ":t:r")

  local prefix = (dir ~= "." and dir ~= "" and (dir .. "/") or "")
  local q = prefix .. base
  return add_dot and (q .. ".") or q
end

---Open picker with only the basename (no directory scope)
function M.open_basename(ctx, opts)
  opts = opts or {}
  local full = ctx.get_fullpath()
  if full == "" then
    return ctx.open("")
  end
  local q = query_basename(full, opts.add_dot ~= false)
  return ctx.open(q)
end

---Open picker scoped to the current file's directory (best-effort in VSCode)
function M.open_dir_scoped(ctx, opts)
  opts = opts or {}
  local full = ctx.get_fullpath()
  if full == "" then
    return ctx.open("")
  end

  local base, dir_abs = split_parts(full)
  local q

  if opts.force_cwd then
    -- "real" directory scoping for pickers that support cwd (Snacks)
    q = (opts.add_dot ~= false) and (base .. ".") or base
    return ctx.open(q, { cwd = dir_abs })
  end

  -- VSCode-style approximation: prefix the query with dir/...
  q = query_dir_prefixed(ctx, full, opts.add_dot ~= false)
  return ctx.open(q)
end

-- ---- Context factories -----------------------------------------------------

function M.ctx_lazyvim_snacks()
  return {
    get_fullpath = function()
      return vim.api.nvim_buf_get_name(0)
    end,
    open = function(query, o)
      o = o or {}
      -- snacks picker config supports `search` and `cwd` :contentReference[oaicite:1]{index=1}
      if o.cwd and o.cwd ~= "" then
        return Snacks.picker.files({ search = query, cwd = o.cwd })
      end
      return Snacks.picker.files({ search = query })
    end,
  }
end

function M.ctx_vscode_quickopen()
  local vscode = require("vscode")
  return {
    get_fullpath = function()
      return vim.api.nvim_buf_get_name(0)
    end,
    relpath = function(fullpath)
      -- relative to current working directory (VSCode usually sets this to workspace root)
      return vim.fn.fnamemodify(fullpath, ":.")
    end,
    open = function(query, _)
      -- Pass query as args to prefill Quick Open
      return vscode.action("workbench.action.quickOpen", { args = { query } })
    end,
  }
end

return M
