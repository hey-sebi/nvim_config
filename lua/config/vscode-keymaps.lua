-- Setup for key bindings when nvim is used from VSCode
if not vim.g.vscode then
  return
end

local map = vim.keymap.set
local ok, vscode = pcall(require, "vscode")
if not ok then
  return
end

-- helper function that calls a VSCode action
local function act(cmd)
  return function()
    vscode.action(cmd)
  end
end

-- helper function that calls a batch of VSCode actions
local function act_many(cmds)
  return function()
    for _, c in ipairs(cmds) do
      vscode.action(c)
    end
  end
end

-- -----------------------------------------------------------------------------
-- Windows / splits (VSCode editor groups)
-- -----------------------------------------------------------------------------
map("n", "<leader>ws", act("workbench.action.splitEditorDown"), { desc = "Split down" })
map("n", "<leader>wv", act("workbench.action.splitEditorRight"), { desc = "Split right" })
map({ "n", "v" }, "<leader>wm", act("workbench.action.moveEditorToNewWindow"), { desc = "Move editor to new window" })

-- Navigate between editor groups (like <C-w>h/j/k/l)
map({ "n", "v" }, "<C-h>", act("workbench.action.navigateLeft"), { desc = "Go to left group" })
map({ "n", "v" }, "<C-j>", act("workbench.action.navigateDown"), { desc = "Go to lower group" })
map({ "n", "v" }, "<C-k>", act("workbench.action.navigateUp"), { desc = "Go to upper group" })
map({ "n", "v" }, "<C-l>", act("workbench.action.navigateRight"), { desc = "Go to right group" })

-- -----------------------------------------------------------------------------
-- Buffers / tabs (VSCode editors)
-- -----------------------------------------------------------------------------
map("n", "<leader>bd", act("workbench.action.closeActiveEditor"), { desc = "Close editor" })
map("n", "<leader>bD", act("workbench.action.closeOtherEditors"), { desc = "Close other editors" })
map("n", "<leader>ba", act("workbench.action.closeAllEditors"), { desc = "Close all editors" })
map("n", "<leader>bl", act("workbench.action.closeEditorsToTheLeft"), { desc = "Close editors to the left" })
map("n", "<leader>br", act("workbench.action.closeEditorsToTheRight"), { desc = "Close editors to the right" })

map("n", "<leader><space>", act("workbench.action.showAllEditors"), { desc = "Show open editors" })
map("n", "<leader>bp", act("workbench.action.openPreviousRecentlyUsedEditor"), { desc = "Prev MRU editor" })
map("n", "<leader>bn", act("workbench.action.openNextRecentlyUsedEditor"), { desc = "Next MRU editor" })

-- Like LazyVim: <S-h>/<S-l> for prev/next tab in group
map({ "n", "v" }, "<S-h>", act("workbench.action.previousEditorInGroup"), { desc = "Prev editor in group" })
map({ "n", "v" }, "<S-l>", act("workbench.action.nextEditorInGroup"), { desc = "Next editor in group" })

-- Keep editor (exit preview mode)
map({ "n", "v" }, "<leader>k", act("workbench.action.keepEditor"), { desc = "Keep editor" })
map("n", "<leader>b<CR>", act("workbench.action.keepEditor"), { desc = "Keep editor" })

-- Header/source toggle (C/C++)
map("n", "<leader>fa", act("C_Cpp.SwitchHeaderSource"), { desc = "Other file (header/source)" })

-- -----------------------------------------------------------------------------
-- Explorer / Git / UI panels
-- -----------------------------------------------------------------------------
-- Simple, robust version of your toggle logic:
-- <leader>e focuses Explorer; <leader>E toggles sidebar visibility.
map("n", "<leader>e", act("workbench.view.explorer"), { desc = "Explorer" })
map("n", "<leader>E", act("workbench.action.toggleSidebarVisibility"), { desc = "Toggle sidebar" })

map("n", "<leader>gg", act_many({ "workbench.view.scm", "workbench.scm.focus" }), { desc = "Git / SCM" })

-- -----------------------------------------------------------------------------
-- Files
-- -----------------------------------------------------------------------------
map("n", "<leader>ff", act("workbench.action.quickOpen"), { desc = "Find files (Quick Open)" })
map("n", "<leader>fo", act("workbench.action.files.openFile"), { desc = "Open file..." })
map("n", "<leader>fr", act("workbench.action.openRecent"), { desc = "Recent files/workspaces" })
map("n", "<leader>fg", act("workbench.action.findInFiles"), { desc = "Find in files" })
map("n", "<leader>fb", act("workbench.action.showAllEditors"), { desc = "Buffers / Editors" })

map({ "n", "v" }, "<leader>fn", act("workbench.action.files.newUntitledFile"), { desc = "New file" })
map({ "n", "v" }, "<leader>fs", act("workbench.action.files.save"), { desc = "Save" })
map({ "n", "v" }, "<leader>fS", act("workbench.action.files.saveAll"), { desc = "Save all" })

-- -----------------------------------------------------------------------------
-- Code / LSP-ish actions (delegated to VSCode)
-- -----------------------------------------------------------------------------
map("n", "K", act("editor.action.showHover"), { desc = "Hover" })

map("n", "<leader>ca", act("editor.action.codeAction"), { desc = "Code action" })
map("n", "<leader>cr", act("editor.action.rename"), { desc = "Rename" })

map({ "n", "v" }, "<leader>cf", act("editor.action.formatDocument"), { desc = "Format document" })
map({ "n", "v" }, "<leader>cF", act("editor.action.formatSelection"), { desc = "Format selection" })

-- Goto
map("n", "gd", act("editor.action.revealDefinition"), { desc = "Goto definition" })
map("n", "gr", act("editor.action.goToReferences"), { desc = "Goto references" })
map("n", "<leader>gd", act("editor.action.revealDefinition"), { desc = "Goto definition" })
map("n", "<leader>gr", act("editor.action.goToReferences"), { desc = "Goto references" })

-- -----------------------------------------------------------------------------
-- Search
-- -----------------------------------------------------------------------------
map({ "n", "v" }, "<leader>sg", act("workbench.action.findInFiles"), { desc = "Search in files" })
map({ "n", "v" }, "<leader>sl", act("actions.find"), { desc = "Search in file" })
map({ "n", "v" }, "<leader>sL", act("editor.action.startFindReplaceAction"), { desc = "Replace in file" })

map("n", "<leader>ss", act("workbench.action.gotoSymbol"), { desc = "Document symbols" })
map("n", "<leader>sS", act("workbench.action.showAllSymbols"), { desc = "Workspace symbols" })

-- Multi-cursor (optional). This can be spicy if you rely on <C-n> in other contexts.
-- Safer alternative is <A-d> like you already used.
map({ "n", "v" }, "<A-d>", act("editor.action.addSelectionToNextFindMatch"), { desc = "Add selection to next match" })
-- map({ "n", "v" }, "<C-n>", act("editor.action.addSelectionToNextFindMatch"), { desc = "Add selection to next match" })

-- Search: <leader>sw = workspace search for word under cursor / visual selection
local function visual_selection_text()
  -- Works in real Neovim (which vscode-neovim runs). We read the buffer text directly.
  local _, ls, cs = unpack(vim.fn.getpos("'<")) -- line, col (1-based)
  local _, le, ce = unpack(vim.fn.getpos("'>"))

  if ls == 0 or le == 0 then
    return ""
  end

  -- Normalize order (in case of backwards selection)
  if ls > le or (ls == le and cs > ce) then
    ls, le = le, ls
    cs, ce = ce, cs
  end

  local lines = vim.api.nvim_buf_get_text(0, ls - 1, cs - 1, le - 1, ce, {})
  local text = table.concat(lines, "\n")
  return text
end

local function workspace_grep_query(query)
  if not query or query == "" then
    return
  end
  vscode.action("workbench.action.findInFiles", {
    -- vscode-neovim: "args" is passed to the VS Code command
    args = {
      query = query,
      triggerSearch = true, -- auto-run the search
    },
  })
end

-- Normal mode: word under cursor
map("n", "<leader>sw", function()
  workspace_grep_query(vim.fn.expand("<cword>"))
end, { desc = "Search word in workspace" })

-- Visual mode: selected text
map("v", "<leader>sw", function()
  workspace_grep_query(visual_selection_text())
end, { desc = "Search selection in workspace" })

-- -----------------------------------------------------------------------------
-- Problems panel (quickfix-ish)
-- -----------------------------------------------------------------------------
map("n", "<leader>jn", act("editor.action.marker.nextInFiles"), { desc = "Next problem" })
map("n", "<leader>jp", act("editor.action.marker.prevInFiles"), { desc = "Prev problem" })
map("n", "<leader>jo", act("workbench.actions.view.problems"), { desc = "Open problems" })
map("n", "<leader>jc", act("workbench.action.closePanel"), { desc = "Close panel" })

-- -----------------------------------------------------------------------------
-- Terminal
-- -----------------------------------------------------------------------------
map("n", "<leader>tt", act("workbench.action.terminal.toggleTerminal"), { desc = "Toggle terminal" })
map("n", "<leader>te", act("workbench.action.focusActiveEditorGroup"), { desc = "Focus editor" })
map("n", "<C-\\>", act("workbench.action.terminal.toggleTerminal"), { desc = "Toggle terminal" })
