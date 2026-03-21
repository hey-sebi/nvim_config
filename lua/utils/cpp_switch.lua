local M = {}

-- ---------------------------------------------------------------------------
-- Switch header/source
--
-- General concept here: Tries LSP based resolution for other file first. If
-- that fails, tries some manually defined patterns.
-- ---------------------------------------------------------------------------

--- @type table<integer, {from: string, to: string[]}>
local alt_patterns = {
  { from = "(.+)%.cpp$", to = { "%1.h", "%1.hpp", "%1.hh", "%1.hxx", "%1_impl.h", "%1-impl.h" } },
  { from = "(.+)%.cc$", to = { "%1.h", "%1.hpp", "%1.hh", "%1.hxx", "%1_impl.h", "%1-impl.h" } },
  { from = "(.+)%.cxx$", to = { "%1.h", "%1.hpp", "%1.hh", "%1.hxx", "%1_impl.h", "%1-impl.h" } },
  { from = "(.+)%.c$", to = { "%1.h" } },
  { from = "(.+)%.h$", to = { "%1.c", "%1.cpp", "%1.cc", "%1.cxx", "%1-impl.h", "%1_impl.h" } },
  { from = "(.+)%.hpp$", to = { "%1.cpp", "%1.cc", "%1.cxx", "%1_impl.h", "%1-impl.h" } },
  { from = "(.+)%.hh$", to = { "%1.cpp", "%1.cc", "%1.cxx" } },
  { from = "(.+)%.hxx$", to = { "%1.cpp", "%1.cc", "%1.cxx" } },
  { from = "(.+)%-impl%.h$", to = { "%1.h", "%1.hpp", "%1.hh", "%1.cpp" } },
  { from = "(.+)%_impl%.h$", to = { "%1.h", "%1.hpp", "%1.hh", "%1.cpp" } },
}

--- Finds all existing alternate files in the same directory using patterns.
--- @param bufname string The full path to the current buffer.
--- @return string[] # A list of found file paths.
function M.find_all_alternates(bufname)
  if bufname == "" then
    return {}
  end
  local dir = vim.fn.fnamemodify(bufname, ":h")
  local fname = vim.fn.fnamemodify(bufname, ":t")
  local found = {}
  local seen = {}

  for _, rule in ipairs(alt_patterns) do
    if fname:match(rule.from) then
      for _, to_pat in ipairs(rule.to) do
        local full = vim.fs.joinpath(dir, fname:gsub(rule.from, to_pat))
        if not seen[full] and vim.uv.fs_stat(full) then
          table.insert(found, full)
          seen[full] = true
        end
      end
    end
  end
  return found
end

--- Swaps between source and header files using clangd.
--- @param bufnr number The buffer number.
--- @param cb fun(alt: string|nil) Callback function to handle the resulting path.
local function clangd_alternate(bufnr, cb)
  local params = { uri = vim.uri_from_bufnr(bufnr) }
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "clangd" })
  --- @type vim.lsp.Client|nil
  local client = clients[1]
  if not client then
    return cb(nil)
  end

  client:request("textDocument/switchSourceHeader", params, function(err, result)
    if err or not result or result == "" then
      return cb(nil)
    end
    cb(vim.uri_to_fname(result))
  end, bufnr)
end

--- Resolves all potential alternates and executes a callback with the choice.
--- @param action_fn fun(target: string)
local function resolve_and_execute(action_fn)
  local bufnr = vim.api.nvim_get_current_buf()
  local current_path = vim.api.nvim_buf_get_name(bufnr)
  local targets = {}
  local seen = { [current_path] = true }

  local function add_target(path)
    if path and not seen[path] then
      table.insert(targets, path)
      seen[path] = true
    end
  end

  clangd_alternate(bufnr, function(lsp_alt)
    add_target(lsp_alt)
    for _, path in ipairs(M.find_all_alternates(current_path)) do
      add_target(path)
    end

    vim.schedule(function()
      if #targets == 0 then
        vim.notify("No alternate file found", vim.log.levels.WARN)
      elseif #targets == 1 then
        action_fn(targets[1])
      else
        -- Using Snacks Picker and let user decide
        Snacks.picker.select(targets, {
          prompt = "Select Alternate:",
          format_item = function(item)
            return vim.fn.fnamemodify(item, ":t")
          end,
        }, function(choice)
          if choice then
            action_fn(choice)
          end
        end)
      end
    end)
  end)
end

--- Trigger a switch to an alternate file inside the same window.
function M.switch_smart()
  resolve_and_execute(function(t)
    vim.cmd.edit(vim.fn.fnameescape(t))
  end)
end

--- Trigger a switch to an alternate file in a vertical split,
--- or reuse that split if it would already exist
function M.switch_smart_vsplit()
  resolve_and_execute(function(t)
    -- Custom logic: check if it's already open elsewhere
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == t then
        vim.api.nvim_set_current_win(win)
        return
      end
    end
    vim.cmd("vsplit " .. vim.fn.fnameescape(t))
  end)
end

return M
