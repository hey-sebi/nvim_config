return {
  "saghen/blink.cmp",
  dependencies = {
    "L3MON4D3/LuaSnip",
    "rafamadriz/friendly-snippets",
  },
  opts = {
    keymap = {
      preset = "super-tab", -- gives <CR> = confirm by default
      ["<Tab>"] = { "fallback" }, -- disable Tab navigation
      ["<S-Tab>"] = { "fallback" }, -- disable Shift-Tab navigation

      -- Your preferred navigation
      ["<C-n>"] = { "select_next", "fallback" },
      ["<C-p>"] = { "select_prev", "fallback" },

      -- Keep Shift-Enter to insert a newline even when menu is open
      ["<S-CR>"] = { "accept_line", "fallback" },
    },

    appearance = {
      use_nvim_cmp_as_default = false,
      nerd_font_variant = "mono",
    },
    signature = { enabled = true },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    completion = {
      menu = { border = "rounded" },
      documentation = { auto_show = true, window = { border = "rounded" } },
      trigger = { show_on_insert_on_trigger_character = true },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
    snippets = { preset = "luasnip" },
  },
  opts_extend = { "sources.default" },
}
