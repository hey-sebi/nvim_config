-- neogen: generate parameter aware code documentation
return {
  {
    "danymat/neogen",
    cond = not vim.g.vscode,
    version = "*", -- track latest stable
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = "Neogen",
    keys = {
      -- Generate doc for the thing under cursor (function by default)
      {
        "<leader>cg",
        function()
          require("neogen").generate()
        end,
        desc = "Generate Doc (Neogen)",
      },
      -- Optional: explicit targets
      {
        "<leader>cgf",
        function()
          require("neogen").generate({ type = "func" })
        end,
        desc = "Generade Doc for Function",
      },
      {
        "<leader>cgc",
        function()
          require("neogen").generate({ type = "class" })
        end,
        desc = "Generade Doc for Class",
      },
      {
        "<leader>cgt",
        function()
          require("neogen").generate({ type = "type" })
        end,
        desc = "Generate Doc for Type",
      },
      {
        "<leader>cgF",
        function()
          require("neogen").generate({ type = "file" })
        end,
        desc = "Generate Doc for File",
      },
    },
    opts = {
      -- Use your snippet engine (LazyVim uses LuaSnip by default)
      snippet_engine = "luasnip",
      enabled = true,
      -- Pick doc styles per language (tweak to taste)
      languages = {
        c = { template = { annotation_convention = "doxygen" } },
        cpp = { template = { annotation_convention = "doxygen" } },
        python = { template = { annotation_convention = "google" } }, -- or "numpy"/"reST"
        javascript = { template = { annotation_convention = "jsdoc" } },
        typescript = { template = { annotation_convention = "tsdoc" } }, -- or "jsdoc"
        typescriptreact = { template = { annotation_convention = "tsdoc" } },
        javascriptreact = { template = { annotation_convention = "jsdoc" } },
        lua = { template = { annotation_convention = "ldoc" } },
      },
    },
  },
}
