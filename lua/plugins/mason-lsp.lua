return {
  "mason-org/mason-lspconfig.nvim",
  cond = not vim.g.vscode,
  opts = {
    -- When an lsp server is configured but missing, install it automatically.
    automatic_installation = true,
  },
}
