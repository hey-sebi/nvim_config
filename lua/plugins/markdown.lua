return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "prettier" },
      },
      formatters = {
        prettier = {
          prepend_args = { "--prose-wrap", "always", "--print-width", "80" },
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = {
            "--config",
            -- Resolves to ~/.config/nvim/... on Unix like systems
            -- and ~/AppData/Local/nvim/... on Windows
            vim.fn.stdpath("config") .. "/.markdownlint-cli2.jsonc",
            "--",
          },
        },
      },
    },
  },
}
