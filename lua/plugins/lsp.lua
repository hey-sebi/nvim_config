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
    init = function()
      -- Suppress benign clangd AST errors for newly created / unindexed header files
      local orig_inlay_hint = vim.lsp.handlers["textDocument/inlayHint"]
      vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, config)
        if err and (err.code == -32602 or (err.message and err.message:find("trying to get AST"))) then
          return
        end
        if orig_inlay_hint then
          return orig_inlay_hint(err, result, ctx, config)
        end
      end
    end,
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
            "--log=error", -- Only log actual errors, avoiding RPC info dumps to stderr
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
