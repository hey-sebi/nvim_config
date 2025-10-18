return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      highlight = { enable = true },
      ensure_installed = {
        "c",
        "cpp",
        "lua",
        "python",
        "bash",
        "vim",
        "vimdoc",
        "regex",
        "javascript",
        "typescript",
        "tsx",
        "json",
        "yaml",
        "xml",
        "cmake",
      },
    },
  },
}
