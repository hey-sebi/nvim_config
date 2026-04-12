return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
                diagnosticMode = "openFilesOnly",
                autoImportCompletions = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
      },
    },
  },
  -- LazyVim's lang.python extra already includes linux-cultist/venv-selector.nvim.
  -- We only need to provide overrides if the defaults don't suffice.
  {
    "linux-cultist/venv-selector.nvim",
    opts = {
      settings = {
        search = {
          my_venvs = {
            command = "fd python.exe$ -H -I -a -E .git -E .venv -E venv -E .direnv",
          },
        },
      },
    },
  },
}
