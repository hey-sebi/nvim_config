local M = {}

-- ---------------------------------------------------------------------------
-- Contains utility functions for switching between "alternate" files in C++
--
-- General concept: Try LSP based resolution for other file first. If
-- that fails, tries some manually defined patterns.
-- ---------------------------------------------------------------------------

local extensions = { "h", "hpp", "hh", "hxx", "c", "cpp", "cc", "cxx" }
local suffixes = { "", "_impl", "-impl", "_p" }

--- Normalize a path for Windows (slashes and casing) to use as a unique key.
local function keypath(path)
  return vim.fs.normalize(path):lower()
end

--- Finds all existing alternate files by permutating suffixes and extensions.
--- @param bufname string The full path to the current buffer.
--- @return string[] # A list of found file paths.
function M.find_all_alternates(bufname)
  if bufname == "" then
    return {}
  end

  local full_path = vim.fs.normalize(bufname)
  local dir = vim.fn.fnamemodify(full_path, ":h")
  local fname = vim.fn.fnamemodify(full_path, ":t")

  -- 1. Extract the base name (domain_impl.cpp -> domain)
  local stem = fname:match("^(.-)%.[^%.]+$") or fname
  local base = stem
  for _, sfx in ipairs({ "_impl", "-impl", "_p" }) do
    if stem:sub(-#sfx) == sfx then
      base = stem:sub(1, -(#sfx + 1))
      break
    end
  end

  -- 2. Build Search Directories (handling deep src/include nesting)
  local search_dirs = { dir }
  -- Common C++ directory swaps
  local swaps = { ["/src/"] = "/include/", ["/src$"] = "/include", ["/source/"] = "/include/" }
  for pattern, subst in pairs(swaps) do
    local alt_dir = dir:gsub(pattern, subst)
    if alt_dir ~= dir then
      table.insert(search_dirs, alt_dir)
    end
  end
  -- Also try the inverse
  for pattern, subst in pairs({ ["/include/"] = "/src/", ["/include$"] = "/src" }) do
    local alt_dir = dir:gsub(pattern, subst)
    if alt_dir ~= dir then
      table.insert(search_dirs, alt_dir)
    end
  end

  -- 3. Search for all permutations
  local found = {}
  local seen = { [keypath(full_path)] = true }

  for _, s_dir in ipairs(search_dirs) do
    for _, sfx in ipairs(suffixes) do
      for _, ext in ipairs(extensions) do
        local target_name = base .. sfx .. "." .. ext
        local full = vim.fs.joinpath(s_dir, target_name)

        local k = keypath(full)
        if not seen[k] and vim.uv.fs_stat(full) then
          table.insert(found, full)
          seen[k] = true
        end
      end
    end
  end
  return found
end

--- Internal orchestrator to resolve the alternate file and execute a callback action.
--- @param action_fn fun(target: string)
local function resolve_and_execute(action_fn)
  local bufnr = vim.api.nvim_get_current_buf()
  local current_path = vim.api.nvim_buf_get_name(bufnr)
  local targets = {}
  local seen = { [keypath(current_path)] = true }

  local snacks = _G.Snacks

  local function add_target(path)
    if not path or path == "" then
      return
    end
    local k = keypath(path)
    if not seen[k] then
      table.insert(targets, path)
      seen[k] = true
    end
  end

  local function finish()
    -- Always run the manual logic to catch the "Triplet" even if LSP only found one
    for _, path in ipairs(M.find_all_alternates(current_path)) do
      add_target(path)
    end

    if #targets == 0 then
      vim.notify("No alternate file found", vim.log.levels.INFO)
    elseif #targets == 1 then
      action_fn(targets[1])
    elseif snacks then
      snacks.picker.select(targets, {
        prompt = "Select Alternate:",
        format_item = function(item)
          local name = vim.fn.fnamemodify(item, ":t")
          local parent = vim.fn.fnamemodify(item, ":h:t")
          return name .. " (" .. parent .. ")"
        end,
      }, function(choice)
        if choice then
          action_fn(choice)
        end
      end)
    end
  end

  -- LSP request (Clangd is usually the source of the truth for non-sibling files)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "clangd" })
  if clients[1] then
    clients[1]:request("textDocument/switchSourceHeader", { uri = vim.uri_from_bufnr(bufnr) }, function(_, result)
      if result and result ~= "" then
        add_target(vim.uri_to_fname(result))
      end
      vim.schedule(finish)
    end, bufnr)
  else
    finish()
  end
end

--- Smartly switches between source and header, using LSP with a local fallback.
function M.switch_smart()
  resolve_and_execute(function(t)
    vim.cmd.edit(vim.fn.fnameescape(t))
  end)
end

--- Switches between source and header in a vertical split.
function M.switch_smart_vsplit()
  resolve_and_execute(function(t)
    local norm_t = keypath(t)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if keypath(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))) == norm_t then
        vim.api.nvim_set_current_win(win)
        return
      end
    end
    vim.cmd("vsplit " .. vim.fn.fnameescape(t))
  end)
end

return M
