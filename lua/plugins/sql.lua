return {
  {
    "tpope/vim-dadbod",
    optional = true,
  },
  {
    "kristijanhusak/vim-dadbod-completion",
    optional = true,
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "dadbod" },
        providers = {
          dadbod = {
            name = "Dadbod",
            module = "vim_dadbod_completion.blink",
            score_offset = 100, -- prioritize dadbod results in SQL files
          },
        },
      },
    },
  },
}
