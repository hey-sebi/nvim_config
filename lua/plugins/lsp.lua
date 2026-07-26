-- We use this settings to inject lua developer API symbols so that the
-- LUA language server properly knows about them.
return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        -- Load the neovim type definitions
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        -- Load LazyVim type definitions
        { path = "lazy.nvim", words = { "LazyVim" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {},
        -- 1. clangd: Enable background indexing for full cross-file LSP navigation
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders=false",
            "--fallback-style=llvm",
            "-j=4", -- Use 4 helper threads for indexing on multi-core CPU
          },
        },
        -- 2. yamlls: Disable automatic SchemaStore fetching and workspace-wide scans
        yamlls = {
          settings = {
            yaml = {
              schemaStore = {
                enable = false,
                url = "",
              },
            },
          },
        },
      },
    },
  },
}
