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
      -- Suppress benign clangd AST errors for newly created / unindexed files
      local function is_benign_clangd_error(err)
        if not err then
          return false
        end
        if err.message and (err.message:find("trying to get AST") or err.message:find("non%-added document")) then
          return true
        end
        return false
      end

      -- 1. Wrap all existing LSP method handlers
      for method, handler in pairs(vim.lsp.handlers) do
        vim.lsp.handlers[method] = function(err, result, ctx, config)
          if is_benign_clangd_error(err) then
            return
          end
          return handler(err, result, ctx, config)
        end
      end

      -- 2. Catch any newly registered handlers dynamically
      local mt = getmetatable(vim.lsp.handlers) or {}
      local orig_newindex = mt.__newindex
      mt.__newindex = function(t, k, v)
        local wrapped_fn = function(err, result, ctx, config)
          if is_benign_clangd_error(err) then
            return
          end
          return v(err, result, ctx, config)
        end
        if orig_newindex then
          orig_newindex(t, k, wrapped_fn)
        else
          rawset(t, k, wrapped_fn)
        end
      end
      setmetatable(vim.lsp.handlers, mt)

      -- 3. Safety net: intercept via vim.notify
      local orig_notify = vim.notify
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.notify = function(msg, level, opts)
        if type(msg) == "string" and (msg:find("trying to get AST") or msg:find("non%-added document")) then
          return
        end
        return orig_notify(msg, level, opts)
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
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.routes = opts.routes or {}
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "trying to get AST",
        },
        opts = { skip = true },
      })
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "non%-added document",
        },
        opts = { skip = true },
      })
    end,
  },
}
