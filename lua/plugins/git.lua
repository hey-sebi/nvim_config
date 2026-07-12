return {
  -- Diffview
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    opts = {},
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
    },
  },

  -- Neogit
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    cmd = { "Neogit" },
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit Status (Tab)" },
      { "<leader>gG", "<cmd>Neogit kind=floating<cr>", desc = "Neogit Status (Float)" },
    },
    opts = {
      disable_commit_confirmation = true,
      integrations = {
        -- Enables integration with diffview.nvim for diffing
        diffview = true,
      },
    },
  },
}
