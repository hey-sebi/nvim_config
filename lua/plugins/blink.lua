return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "super-tab",
        ["<Tab>"] = {
          function(cmp)
            if cmp.is_menu_visible() then
              return cmp.select_and_accept()
            end
            if cmp.snippet_active() then
              return cmp.snippet_forward()
            end
          end,
          "fallback",
        },
        ["<S-Tab>"] = {
          function(cmp)
            if cmp.snippet_active() then
              return cmp.snippet_backward()
            end
          end,
          "fallback",
        },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        -- If we manually scroll down the menu with C-n, hitting Enter will
        -- accept it. Otherwise, it just inserts a newline.
        ["<CR>"] = { "accept", "fallback" },
        ["<S-CR>"] = { "fallback" },
      },
      completion = {
        menu = { border = "rounded" },
        documentation = { auto_show = true, window = { border = "rounded" } },
      },
      signature = { enabled = true },
      -- Ensure buffer text and paths are highly prioritized to compensate for
      -- legacy indexing gaps
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },
}
