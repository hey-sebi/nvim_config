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
      },
    },
  },
}
