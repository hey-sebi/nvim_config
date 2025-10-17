return {
  "saghen/blink.cmp",
  dependencies = {
    "L3MON4D3/LuaSnip",
    "rafamadriz/friendly-snippets",
  },
  opts = function(_, opts)
    local presets = require("blink.cmp.keymap.presets")
    local km = presets.get("super-tab")

    -- disable Tab/Shift-Tab
    km["<Tab>"] = false
    km["<S-Tab>"] = false

    -- navigation among the suggestions
    km["<C-n>"] = { "select_next", "fallback_to_mappings" }
    km["<C-p>"] = { "select_prev", "fallback_to_mappings" }

    -- Shift-Enter: always newline
    km["<S-CR>"] = { "fallback" }
    -- Enter: confirm the suggestion
    -- Accept currently selected item; if none selected, pick the top entry.
    -- If no menu is open, fall back to normal Enter.
    km["<CR>"] = { "select_and_accept", "fallback" }

    -- normalize anything that might be a string in this preset
    local function as_list(v)
      if v == false or type(v) == "table" then
        return v
      end
      if type(v) == "string" then
        return { v }
      end
      return v
    end
    km["<CR>"] = as_list(km["<CR>"]) -- keep preset behavior, ensure list

    opts.keymap = km
    -- (rest of your opts kept the same)
    opts.appearance = vim.tbl_deep_extend("force", opts.appearance or {}, {
      use_nvim_cmp_as_default = false,
      nerd_font_variant = "mono",
    })
    opts.signature = { enabled = true }
    opts.sources = opts.sources or {}
    opts.sources.default = { "lsp", "path", "snippets", "buffer" }
    opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
      menu = { border = "rounded" },
      documentation = { auto_show = true, window = { border = "rounded" } },
      trigger = { show_on_insert_on_trigger_character = true },
    })
    opts.fuzzy = opts.fuzzy or { implementation = "prefer_rust_with_warning" }
    opts.snippets = { preset = "luasnip" }
    return opts
  end,
  opts_extend = { "sources.default" },
}
