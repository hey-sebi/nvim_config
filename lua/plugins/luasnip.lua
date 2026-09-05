return {
  {
    "rafamadriz/friendly-snippets",
    config = function()
      -- Load default friendly-snippets
      -- To completely disable default C/C++ snippets, add:
      --   exclude = { "c", "cpp" }
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Load user custom snippets with higher priority (2000 vs 1000)
      -- so custom snippets override default ones on identical triggers (e.g. "for", "foreach")
      require("luasnip.loaders.from_vscode").lazy_load({
        paths = { vim.fn.stdpath("config") .. "/snippets" },
        override_priority = 2000,
      })
    end,
  },
}
