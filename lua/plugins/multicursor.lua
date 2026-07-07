return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  keys = {
    -- We define keys here to trigger lazy-loading of the plugin
    { "<leader>mk", mode = { "n", "x" } },
    { "<leader>mj", mode = { "n", "x" } },
    { "<leader>mK", mode = { "n", "x" } },
    { "<leader>mJ", mode = { "n", "x" } },
    { "<leader>mn", mode = { "n", "x" } },
    { "<leader>mN", mode = { "n", "x" } },
    { "<leader>ms", mode = { "n", "x" } },
    { "<leader>mS", mode = { "n", "x" } },
    { "<leader>ma", mode = { "n", "x" } },
    { "<leader>mm", mode = { "n", "x" } },
    { "<leader>mc", mode = { "n", "x" } },
  },
  config = function()
    local mc = require("multicursor-nvim")

    mc.setup()

    local set = vim.keymap.set

    -- Add or skip cursor above/below the main cursor
    set({ "n", "x" }, "<leader>mk", function() mc.lineAddCursor(-1) end, { desc = "Add cursor above" })
    set({ "n", "x" }, "<leader>mj", function() mc.lineAddCursor(1) end, { desc = "Add cursor below" })
    set({ "n", "x" }, "<leader>mK", function() mc.lineSkipCursor(-1) end, { desc = "Skip cursor above" })
    set({ "n", "x" }, "<leader>mJ", function() mc.lineSkipCursor(1) end, { desc = "Skip cursor below" })

    -- Add or skip adding a new cursor by matching word/selection
    set({ "n", "x" }, "<leader>mn", function() mc.matchAddCursor(1) end, { desc = "Match next word" })
    set({ "n", "x" }, "<leader>mN", function() mc.matchAddCursor(-1) end, { desc = "Match prev word" })
    set({ "n", "x" }, "<leader>ms", function() mc.matchSkipCursor(1) end, { desc = "Skip next word" })
    set({ "n", "x" }, "<leader>mS", function() mc.matchSkipCursor(-1) end, { desc = "Skip prev word" })

    -- Add all matches in the document
    set({ "n", "x" }, "<leader>ma", function() mc.matchAllAddCursors() end, { desc = "Match all words" })

    -- Toggle/enable/disable current cursor
    set({ "n", "x" }, "<leader>mm", mc.toggleCursor, { desc = "Toggle cursor" })

    -- Clear all cursors (escape hatch)
    set({ "n", "x" }, "<leader>mc", mc.disableCursors, { desc = "Clear all cursors" })

    -- Customize highlights to ensure visual compatibility with colorschemes
    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { link = "Cursor" })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
    hl(0, "MultiCursorDisabledVisual", { link = "Visual" })

    -- Mappings defined in a keymap layer only apply when there are multiple cursors
    mc.addKeymapLayer(function(layerSet)
      -- Allow pressing escape to clear all extra cursors
      layerSet({ "n", "x" }, "<esc>", mc.disableCursors, { desc = "Clear all cursors" })

      -- Rotate/navigate through existing cursors
      layerSet({ "n", "x" }, "<leader>mh", mc.prevCursor, { desc = "Go to prev cursor" })
      layerSet({ "n", "x" }, "<leader>ml", mc.nextCursor, { desc = "Go to next cursor" })

      -- Delete current cursor
      layerSet({ "n", "x" }, "<leader>md", mc.deleteCursor, { desc = "Delete cursor" })
    end)
  end,
}
