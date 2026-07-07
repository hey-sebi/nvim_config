return {
  {
    "neovim/nvim-lspconfig",
    cond = not vim.g.vscode,
    opts = {
      servers = {
        cmake = {
          enabled = false,
        },
        neocmake = {
          enabled = false,
        },
      },
    },
  },

  -- {
  --   "stevearc/conform.nvim",
  --   opts = function(_, opts)
  --     opts.formatters = opts.formatters or {}
  --     opts.formatters_by_ft = opts.formatters_by_ft or {}
  --
  --     local is_win = vim.fn.has("win32") == 1
  --
  --     if is_win then
  --       -- Windows: ensure .CMD shim is executable by routing through cmd.exe
  --       -- This is relevant as cmake-format is shimmed
  --       opts.formatters.cmake_format_cmd = {
  --         command = "cmd.exe",
  --         args = { "/c", "cmake-format", "-" },
  --         stdin = true,
  --       }
  --       opts.formatters_by_ft.cmake = { "cmake_format_cmd" }
  --     else
  --       -- Linux/macOS: direct invocation is fine
  --       opts.formatters_by_ft.cmake = { "cmake-format" }
  --     end
  --   end,
  -- },
}
