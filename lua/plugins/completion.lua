-- lua/plugins/completion.lua
return {
  "saghen/blink.cmp",
  -- If your LazyVim is recent, version pin is optional; keep master-compatible
  -- version = "v0.*",
  dependencies = {
    "L3MON4D3/LuaSnip", -- snippets engine (LazyVim already has it, but safe)
    "rafamadriz/friendly-snippets", -- nice snippet collection (optional)
  },
  opts = {
    -- Good defaults; feel free to tweak
    keymap = { preset = "default" },

    appearance = {
      -- independent UI
      use_nvim_cmp_as_default = false,
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = "mono",
    },
    signature = { enabled = true }, -- LSP signature popups
    sources = {
      -- order matters; lsp first
      default = { "lsp", "path", "snippets", "buffer" },
    },
    completion = {
      menu = { border = "rounded" },
      documentation = { auto_show = true, window = { border = "rounded" } },
      trigger = { show_on_insert_on_trigger_character = true },
    },

    fuzzy = { implementation = "prefer_rust_with_warning" },
    snippets = { preset = "luasnip" }, -- use LuaSnip for ${1} style placeholders
  },

  -- don't override, but extend options
  opts_extend = { "sources.default" },
}
