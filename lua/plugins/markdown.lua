return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "prettier" },
      },
      formatters = {
        prettier = {
          prepend_args = { "--prose-wrap", "always", "--print-width", "100" },
        },
      },
    },
  },
}
