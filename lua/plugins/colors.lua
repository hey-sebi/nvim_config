return {
  -- Configure LazyVim active colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-macchiato",
    },
  },

  -- Catppuccin theme configuration
  {
    "catppuccin/nvim",
    name = "catppuccin",
    cond = not vim.g.vscode,
    priority = 1000,
    opts = {
      flavour = "macchiato", -- latte, frappe, macchiato, mocha
      background = {
        light = "macchiato",
        dark = "frappe",
      },
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      dim_inactive = {
        enabled = false,
      },
      no_italic = true,
      styles = {
        comments = {},
        conditionals = {},
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
      color_overrides = {},
      custom_highlights = function(colors)
        return {
          -- Place custom highlight overrides here
        }
      end,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = true,
        mini = {
          enabled = true,
        },
      },
    },
  },

  -- Tokyo Night theme configuration
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
