local M = {}

-- ---------------------------------------------------------------------------
-- Switch header/source
--
-- General concept here: Tries LSP based resolution for other file first. If
-- that fails, tries some manually defined patterns.
-- ---------------------------------------------------------------------------

--- @type table<integer, {from: string, to: string[]}>
local alt_patterns = {
  { from = "(.+)%.cpp$", to = { "%1.h", "%1.hpp", "%1.hh", "%1.hxx" } },
  { from = "(.+)%.cc$", to = { "%1.h", "%1.hpp", "%1.hh", "%1.hxx" } },
  { from = "(.+)%.cxx$", to = { "%1.h", "%1.hpp", "%1.hh", "%1.hxx" } },
  { from = "(.+)%.c$", to = { "%1.h" } },
  { from = "(.+)%.h$", to = { "%1.c", "%1.cpp", "%1.cc", "%1.cxx", "%1-impl.h" } },
  { from = "(.+)%.hpp$", to = { "%1.cpp", "%1.cc", "%1.cxx" } },
  { from = "(.+)%.hh$", to = { "%1.cpp", "%1.cc", "%1.cxx" } },
  { from = "(.+)%.hxx$", to = { "%1.cpp", "%1.cc", "%1.cxx" } },
  { from = "(.+)%-impl%.h$", to = { "%1.h", "%1.hpp", "%1.hh" } },
}

--- Find alternate file in same directory using our patterns
--- @param bufname string The full path to the current buffer
--- @return string|nil # The path to the alternate file, or nil if not found
local function find_alternate_same_dir(bufname)
  if bufname == "" then
    return nil
  end
  local dir = vim.fn.fnamemodify(bufname, ":h")
  local fname = vim.fn.fnamemodify(bufname, ":t")

  for _, rule in ipairs(alt_patterns) do
    if fname:match(rule.from) then
      for _, to_pat in ipairs(rule.to) do
        -- Platform-agnostic path joining
        local full = vim.fs.joinpath(dir, fname:gsub(rule.from, to_pat))

        if vim.uv.fs_stat(full) then
          return full
        end
      end
    end
  end

  return nil
end

--- Jump to existing window showing `target`, or open in vsplit if not visible
--- @param target string The full path of the file to jump to
local function jump_or_vsplit(target)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == target then
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  vim.cmd("vsplit " .. vim.fn.fnameescape(target))
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

  -- Using colon syntax to satisfy the 'self' argument requirement
  client:request("textDocument/switchSourceHeader", params, function(err, result)
    if err or not result or result == "" then
      return cb(nil)
    end
    -- result is a URI string
    cb(vim.uri_to_fname(result))
  end, bufnr)
end

--- Internal orchestrator to resolve the alternate file and execute a callback action.
--- @param action_fn fun(target: string) The function to execute once a file is found.
local function resolve_and_execute(action_fn)
  local bufnr = vim.api.nvim_get_current_buf()
  local before = vim.api.nvim_buf_get_name(bufnr)

  clangd_alternate(bufnr, function(alt)
    local target = alt or find_alternate_same_dir(before)

    if target then
      vim.schedule(function()
        action_fn(target)
      end)
    else
      vim.notify("No alternate file found for " .. vim.fn.fnamemodify(before, ":t"), vim.log.levels.INFO)
    end
  end)
end

--- Smartly switches between source and header, using LSP with a local fallback.
function M.switch_source_header_smart()
  resolve_and_execute(function(target)
    vim.cmd.edit(vim.fn.fnameescape(target))
  end)
end

--- Switches between source and header in a vertical split.
function M.switch_source_header_vsplit()
  resolve_and_execute(jump_or_vsplit)
end

--- Registers user commands for the switch functions.
--- This allows calling :Switch or :SwitchSplit from the command line.
vim.api.nvim_create_user_command("Switch", function()
  M.switch_source_header_smart()
end, { desc = "Switch between source and header" })

vim.api.nvim_create_user_command("SwitchSplit", function()
  M.switch_source_header_vsplit()
end, { desc = "Switch between source and header in vsplit" })

return M
