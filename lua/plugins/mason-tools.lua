return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  event = "VeryLazy",
  opts = {
    ensure_installed = {
      -- LSP servers
      "clangd",
      "pyright",
      "tsserver",
      "json-lsp",
      "yaml-language-server",
      "bash-language-server",
      -- Formatters
      "clang-format",
      "black",
      "ruff",
      "stylua",
      "prettierd",
      "shfmt",
      -- Linters
      "shellcheck",
      "yamllint",
      "jsonlint",
      -- (optional) DAPs
      "codelldb",
      "debugpy",
    },
    auto_update = true, -- keep tools fresh
    run_on_start = true, -- install anything missing on startup
    start_delay = 50, -- a tiny delay so UI doesn’t flicker
    debounce_hours = 24, -- don’t re-check too often
  },
}
