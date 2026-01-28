return {
  {
    "folke/tokyonight.nvim",
    cond = not vim.g.vscode,
    opts = {
      style = "storm",
      styles = {
        comments = { italic = false },
        keywords = { italic = false },
      },
      on_highlights = function(hl, c)
        local lavender_gray = "#9aa5ce"
        local orange = "#ff9e64"
        -- ----------------------------------------------
        -- line numbers
        -- ----------------------------------------------
        hl.LineNrAbove = { fg = lavender_gray }
        hl.LineNrBelow = { fg = lavender_gray }
        -- when relativenumber = off
        hl.LineNr = { fg = lavender_gray }
        hl.CursorLineNr = { fg = orange, bold = true }

        -- ----------------------------------------------
        -- comments with higher contrast
        -- ----------------------------------------------
        hl.Comment = { fg = lavender_gray, italic = false }
      end,
    },
  },
}
