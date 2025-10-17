-- Python language setup

return {
  -- 1) Mason: make sure Python tools get installed
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- LSP servers
        "basedpyright", -- or "pyright" if you prefer, just enable it below
        "ruff-lsp",
        -- Formatters / linters
        "ruff",
        "black",
        "isort",
        "mypy",
        -- Debugger
        "debugpy",
      })
    end,
  },

  -- 2) LSP: configure the server
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Choose one of these two; basedpyright shown by default:
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard", -- "off" | "basic" | "standard" | "strict"
                diagnosticMode = "openFilesOnly",
                autoImportCompletions = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        -- pyright = { settings = { python = { analysis = { typeCheckingMode = "basic" } } } },

        ruff_lsp = {
          init_options = {
            settings = {
              args = {}, -- e.g. { "--line-length", "100" }
            },
          },
          -- on_attach = function(client, _)
          --   client.server_capabilities.documentFormattingProvider = false
          -- end,
        },
      },
    },
  },

  -- 3) Formatting via Conform: Choose one. Ruff (or Black+Isort below)
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      -- Option A (default): Ruff does both format + organize imports
      opts.formatters_by_ft.python = { "ruff_format", "ruff_organize_imports" }

      -- Option B: Black + Isort (uncomment to use instead)
      -- opts.formatters_by_ft.python = { "isort", "black" }

      opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
        ruff_format = {
          command = "ruff",
          args = { "format", "--stdin-filename", "$FILENAME", "-" },
        },
        ruff_organize_imports = {
          command = "ruff",
          args = { "check", "--select", "I", "--fix", "--stdin-filename", "$FILENAME", "-" },
        },
      })
    end,
  },

  -- 4) Completion tweaks for blink
  -- {
  --   "saghen/blink.cmp",
  --   -- optional = true,
  --   opts = {
  --     keymap = { preset = "super-tab" }, -- Tab/Shift-Tab navigate, Enter confirms
  --     sources = { default = { "lsp", "path", "snippets", "buffer" } },
  --     signature = { enabled = true },
  --   },
  -- },

  -- 5) Virtualenv QoL (optional; safe no-op if you don’t use it)
  {
    "linux-cult/venv-selector.nvim",
    optional = true,
    opts = {
      auto_refresh = true,
      settings = {
        search = { my_venvs = { ".venv", "venv", ".direnv/python-*/" }, parents = 4 },
      },
    },
  },

  -- 6) (Optional) Testing: enable only if you already use neotest
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "nvim-neotest/neotest-python" },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(
        opts.adapters,
        require("neotest-python")({
          runner = "pytest",
          dap = { justMyCode = false },
        })
      )
    end,
  },
}
