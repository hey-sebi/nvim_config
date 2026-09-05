local M = {}

-- ---------------------------------------------------------------------------
-- Contains utility functions for switching between "alternate" files in C++
--
-- General concept: Try LSP based resolution for other file first. If
-- that fails, tries some manually defined patterns.
-- ---------------------------------------------------------------------------

local header_exts = { "h", "hpp", "hh", "hxx" }
local source_exts = { "cpp", "cc", "cxx", "c" }
local suffixes = { "", "_impl", "-impl", "_p", "Impl", "Private", "-private", "_private" }

--- Determines if the extension indicates a header file.
--- @param ext string
--- @return boolean
local function is_header_ext(ext)
  local e = ext:lower()
  for _, h_ext in ipairs(header_exts) do
    if e == h_ext then
      return true
    end
  end
  return false
end

--- Get prioritized extensions list based on current file extension.
--- @param ext string
--- @return string[]
local function get_prioritized_extensions(ext)
  local prioritized = {}
  local primary = header_exts
  local secondary = source_exts

  if is_header_ext(ext) then
    primary = source_exts
    secondary = header_exts
  end

  for _, e in ipairs(primary) do
    table.insert(prioritized, e)
  end
  for _, e in ipairs(secondary) do
    table.insert(prioritized, e)
  end
  return prioritized
end

--- Check if a path contains an 'include' component.
--- @param path string
--- @return boolean
local function has_include_component(path)
  local lp = path:lower()
  return lp:match("[/\\]include[/\\]") or lp:match("[/\\]include$")
end

--- Normalize a path for Windows (slashes and casing) to use as a unique key.
local function keypath(path)
  return vim.fs.normalize(path):lower()
end

--- Get the primary default target extension for a given file extension.
--- @param ext string
--- @return string
local function get_default_target_ext(ext)
  local e = ext:lower()
  if e == "hpp" then return "cpp" end
  if e == "hxx" then return "cxx" end
  if e == "hh" then return "cc" end
  if e == "h" then return "cpp" end
  if e == "cpp" then return "hpp" end
  if e == "cxx" then return "hxx" end
  if e == "cc" then return "hh" end
  if e == "c" then return "h" end
  return is_header_ext(e) and "cpp" or "hpp"
end

--- Suggests the best candidate path for an alternate file if none currently exists.
--- @param full_path string
--- @return string
function M.suggest_alternate(full_path)
  full_path = vim.fs.normalize(full_path)
  local dir = vim.fn.fnamemodify(full_path, ":h")
  local fname = vim.fn.fnamemodify(full_path, ":t")
  local ext = fname:match("%.([^%.]+)$") or ""
  local stem = fname:match("^(.-)%.[^%.]+$") or fname
  local target_ext = get_default_target_ext(ext)

  local root = vim.fs.root(full_path, { ".git", ".neoconf.json", "CMakeLists.txt" }) or dir

  local target_dir = dir
  if is_header_ext(ext) then
    -- Header -> Source: try include -> src
    local candidate = nil
    if dir:match("/include/") or dir:match("/include$") then
      candidate = dir:gsub("/include/", "/src/"):gsub("/include$", "/src")
    elseif dir:match("/Include/") or dir:match("/Include$") then
      candidate = dir:gsub("/Include/", "/Src/"):gsub("/Include$", "/Src")
    end

    if candidate and (vim.uv.fs_stat(candidate) or vim.uv.fs_stat(root .. "/src") or vim.uv.fs_stat(root .. "/Src")) then
      target_dir = candidate
    elseif candidate then
      target_dir = candidate
    elseif vim.uv.fs_stat(root .. "/src") then
      local rel_to_root = vim.fs.normalize(vim.fn.fnamemodify(dir, ":.")):gsub("^include/?", "")
      target_dir = vim.fs.normalize(root .. "/src/" .. rel_to_root)
    end
  else
    -- Source -> Header: try src -> include
    local candidate = nil
    if dir:match("/src/") or dir:match("/src$") then
      candidate = dir:gsub("/src/", "/include/"):gsub("/src$", "/include")
    elseif dir:match("/source/") or dir:match("/source$") then
      candidate = dir:gsub("/source/", "/include/"):gsub("/source$", "/include")
    elseif dir:match("/Src/") or dir:match("/Src$") then
      candidate = dir:gsub("/Src/", "/Include/"):gsub("/Src$", "/Include")
    end

    if candidate and (vim.uv.fs_stat(candidate) or vim.uv.fs_stat(root .. "/include") or vim.uv.fs_stat(root .. "/Include")) then
      target_dir = candidate
    elseif candidate then
      target_dir = candidate
    elseif vim.uv.fs_stat(root .. "/include") then
      local rel_to_root = vim.fs.normalize(vim.fn.fnamemodify(dir, ":.")):gsub("^src/?", ""):gsub("^source/?", "")
      target_dir = vim.fs.normalize(root .. "/include/" .. rel_to_root)
    end
  end

  return vim.fs.normalize(target_dir .. "/" .. stem .. "." .. target_ext)
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
  local ext = fname:match("%.([^%.]+)$") or ""
  local search_extensions = get_prioritized_extensions(ext)

  -- 1. Extract the base name (domain_impl.cpp -> domain) using defined suffixes
  local stem = fname:match("^(.-)%.[^%.]+$") or fname
  local base = stem
  for _, sfx in ipairs(suffixes) do
    if sfx ~= "" and stem:sub(-#sfx) == sfx then
      base = stem:sub(1, -(#sfx + 1))
      break
    end
  end

  -- 2. Build Search Directories (handling deep src/include nesting by swapping only the last occurrence)
  local search_dirs = { dir }

  -- Try swapping src/source to include
  local src_to_include_patterns = {
    -- Lowercase
    { pattern = "(.*)/src/lib/(.*)", repl = "%1/include/%2" },
    { pattern = "(.*)/src/libs/(.*)", repl = "%1/include/%2" },
    { pattern = "(.*)/src/(.*)", repl = "%1/include/%2" },
    { pattern = "(.*)/src$", repl = "%1/include" },
    { pattern = "(.*)/source/lib/(.*)", repl = "%1/include/%2" },
    { pattern = "(.*)/source/libs/(.*)", repl = "%1/include/%2" },
    { pattern = "(.*)/source/(.*)", repl = "%1/include/%2" },
    { pattern = "(.*)/source$", repl = "%1/include" },
    -- Capitalized
    { pattern = "(.*)/Src/Lib/(.*)", repl = "%1/Include/%2" },
    { pattern = "(.*)/Src/Libs/(.*)", repl = "%1/Include/%2" },
    { pattern = "(.*)/Src/(.*)", repl = "%1/Include/%2" },
    { pattern = "(.*)/Src$", repl = "%1/Include" },
    { pattern = "(.*)/Source/Lib/(.*)", repl = "%1/Include/%2" },
    { pattern = "(.*)/Source/Libs/(.*)", repl = "%1/Include/%2" },
    { pattern = "(.*)/Source/(.*)", repl = "%1/Include/%2" },
    { pattern = "(.*)/Source$", repl = "%1/Include" },
    -- Uppercase
    { pattern = "(.*)/SRC/LIB/(.*)", repl = "%1/INCLUDE/%2" },
    { pattern = "(.*)/SRC/LIBS/(.*)", repl = "%1/INCLUDE/%2" },
    { pattern = "(.*)/SRC/(.*)", repl = "%1/INCLUDE/%2" },
    { pattern = "(.*)/SRC$", repl = "%1/INCLUDE" },
    { pattern = "(.*)/SOURCE/LIB/(.*)", repl = "%1/INCLUDE/%2" },
    { pattern = "(.*)/SOURCE/LIBS/(.*)", repl = "%1/INCLUDE/%2" },
    { pattern = "(.*)/SOURCE/(.*)", repl = "%1/INCLUDE/%2" },
    { pattern = "(.*)/SOURCE$", repl = "%1/INCLUDE" },
  }
  local matched_src = false
  for _, item in ipairs(src_to_include_patterns) do
    local alt_dir, count = dir:gsub(item.pattern, item.repl)
    if count > 0 then
      table.insert(search_dirs, alt_dir)
      matched_src = true
    end
  end

  if not matched_src and not has_include_component(dir) then
    table.insert(search_dirs, vim.fs.joinpath(dir, "include"))
    table.insert(search_dirs, vim.fs.joinpath(dir, "Include"))
    table.insert(search_dirs, vim.fs.joinpath(dir, "INCLUDE"))
  end

  -- Try swapping include to src/source
  local include_to_src_patterns = {
    -- Lowercase
    { pattern = "(.*)/include/(.*)", repl = "%1/src/lib/%2" },
    { pattern = "(.*)/include/(.*)", repl = "%1/src/libs/%2" },
    { pattern = "(.*)/include/(.*)", repl = "%1/src/%2" },
    { pattern = "(.*)/include$", repl = "%1/src" },
    { pattern = "(.*)/include/(.*)", repl = "%1/source/lib/%2" },
    { pattern = "(.*)/include/(.*)", repl = "%1/source/libs/%2" },
    { pattern = "(.*)/include/(.*)", repl = "%1/source/%2" },
    { pattern = "(.*)/include$", repl = "%1/source" },
    { pattern = "(.*)/include/(.*)", repl = "%1/%2" },
    { pattern = "(.*)/include/(.*)", repl = "%1" },
    { pattern = "(.*)/include$", repl = "%1" },

    -- Capitalized
    { pattern = "(.*)/Include/(.*)", repl = "%1/Src/Lib/%2" },
    { pattern = "(.*)/Include/(.*)", repl = "%1/Src/Libs/%2" },
    { pattern = "(.*)/Include/(.*)", repl = "%1/Src/%2" },
    { pattern = "(.*)/Include$", repl = "%1/Src" },
    { pattern = "(.*)/Include/(.*)", repl = "%1/Source/Lib/%2" },
    { pattern = "(.*)/Include/(.*)", repl = "%1/Source/Libs/%2" },
    { pattern = "(.*)/Include/(.*)", repl = "%1/Source/%2" },
    { pattern = "(.*)/Include$", repl = "%1/Source" },
    { pattern = "(.*)/Include/(.*)", repl = "%1/%2" },
    { pattern = "(.*)/Include/(.*)", repl = "%1" },
    { pattern = "(.*)/Include$", repl = "%1" },

    -- Uppercase
    { pattern = "(.*)/INCLUDE/(.*)", repl = "%1/SRC/LIB/%2" },
    { pattern = "(.*)/INCLUDE/(.*)", repl = "%1/SRC/LIBS/%2" },
    { pattern = "(.*)/INCLUDE/(.*)", repl = "%1/SRC/%2" },
    { pattern = "(.*)/INCLUDE$", repl = "%1/SRC" },
    { pattern = "(.*)/INCLUDE/(.*)", repl = "%1/SOURCE/LIB/%2" },
    { pattern = "(.*)/INCLUDE/(.*)", repl = "%1/SOURCE/LIBS/%2" },
    { pattern = "(.*)/INCLUDE/(.*)", repl = "%1/SOURCE/%2" },
    { pattern = "(.*)/INCLUDE$", repl = "%1/SOURCE" },
    { pattern = "(.*)/INCLUDE/(.*)", repl = "%1/%2" },
    { pattern = "(.*)/INCLUDE/(.*)", repl = "%1" },
    { pattern = "(.*)/INCLUDE$", repl = "%1" },
  }
  for _, item in ipairs(include_to_src_patterns) do
    local alt_dir, count = dir:gsub(item.pattern, item.repl)
    if count > 0 then
      table.insert(search_dirs, alt_dir)
    end
  end

  -- 3. Phase 1: Fast direct fs_stat checks for all path pattern swaps (instant)
  local found = {}
  local seen = { [keypath(full_path)] = true }

  for _, s_dir in ipairs(search_dirs) do
    if vim.uv.fs_stat(s_dir) then
      for _, sfx in ipairs(suffixes) do
        for _, target_ext in ipairs(search_extensions) do
          local target_name = base .. sfx .. "." .. target_ext
          local full = vim.fs.joinpath(s_dir, target_name)

          local k = keypath(full)
          if not seen[k] and vim.uv.fs_stat(full) then
            table.insert(found, full)
            seen[k] = true
          end
        end
      end
    end
  end

  -- Phase 2: If direct stat found targets, return immediately!
  if #found > 0 then
    return found
  end

  -- Phase 3: Ultra-fast ripgrep (rg) workspace search if direct stat missed (170ms)
  local root = vim.fs.root(0, { ".git", ".neoconf.json" }) or vim.uv.cwd()
  local glob_pattern = base .. "*"
  local cmd = { "rg", "--files", "--ignore-case", "-g", glob_pattern }

  local ok, lines = pcall(vim.fn.systemlist, cmd)
  if ok and type(lines) == "table" then
    for _, rel_file in ipairs(lines) do
      local full_file = vim.fs.normalize(vim.fs.joinpath(root, rel_file))
      local file_ext = full_file:match("%.([^%.]+)$") or ""
      if is_header_ext(ext) ~= is_header_ext(file_ext) then
        local k = keypath(full_file)
        if not seen[k] and vim.uv.fs_stat(full_file) then
          table.insert(found, full_file)
          seen[k] = true
        end
      end
    end
  end

  return found
end

--- Orchestrator to resolve the alternate file and execute a callback action.
--- @param action_fn fun(target: string)
--- @param opts? { create_if_missing?: boolean }
local function resolve_and_execute(action_fn, opts)
  opts = opts or {}
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
      if opts.create_if_missing then
        local suggested = M.suggest_alternate(current_path)
        local rel_suggested = vim.fn.fnamemodify(suggested, ":.")

        local choice_create = string.format("Create '%s'", rel_suggested)
        local choice_custom = "Specify custom path..."
        local choice_cancel = "Cancel"

        local function handle_choice(choice)
          if choice == choice_create then
            local parent = vim.fs.dirname(suggested)
            if parent and parent ~= "" and not vim.uv.fs_stat(parent) then
              vim.fn.mkdir(parent, "p")
            end
            action_fn(suggested)
          elseif choice == choice_custom then
            vim.ui.input({
              prompt = "Path to create: ",
              default = rel_suggested,
            }, function(custom_input)
              if custom_input and vim.trim(custom_input) ~= "" then
                local root = vim.fs.root(current_path, { ".git", ".neoconf.json", "CMakeLists.txt" }) or vim.fn.getcwd()
                local full_custom = vim.fs.normalize(vim.fs.joinpath(root, vim.trim(custom_input)))
                local parent = vim.fs.dirname(full_custom)
                if parent and parent ~= "" and not vim.uv.fs_stat(parent) then
                  vim.fn.mkdir(parent, "p")
                end
                action_fn(full_custom)
              end
            end)
          end
        end

        local choices = { choice_create, choice_custom, choice_cancel }
        if snacks then
          snacks.picker.select(choices, {
            prompt = "Alternate file not found. Create it?:",
          }, function(choice)
            if choice then
              handle_choice(choice)
            end
          end)
        else
          vim.ui.select(choices, {
            prompt = "Alternate file not found. Create it?:",
          }, function(choice)
            if choice then
              handle_choice(choice)
            end
          end)
        end
      else
        vim.notify("No alternate file found", vim.log.levels.INFO)
      end
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
    else
      vim.ui.select(targets, {
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

  -- Find any client supporting textDocument/switchSourceHeader (e.g. clangd, ccls)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local lsp_client = nil
  for _, client in ipairs(clients) do
    if client:supports_method("textDocument/switchSourceHeader") then
      lsp_client = client
      break
    end
  end

  if lsp_client then
    lsp_client:request("textDocument/switchSourceHeader", { uri = vim.uri_from_bufnr(bufnr) }, function(_, result)
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

M.resolve_and_execute = resolve_and_execute

return M
