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
        -- 1. clangd: Disable codebase-wide background indexing and limit worker threads
        clangd = {
          cmd = {
            "clangd",
            "--background-index=false", -- Disable background indexing of the entire codebase
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders=false",
            "--fallback-style=llvm",
            "-j=2", -- Limit helper threads to 2 to prevent CPU starvation
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
