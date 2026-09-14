return {
  {
    "saghen/blink.cmp",
    dependencies = {
      {
        "mikavilpas/blink-ripgrep.nvim",
        version = "*",
      },
    },
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
      sources = {
        -- Priority ordering: LSP > buffer > ripgrep
        default = { "lsp", "path", "snippets", "buffer", "ripgrep" },
        providers = {
          lsp = {
            score_offset = 0,
          },
          buffer = {
            score_offset = -3,
            opts = {
              -- Index all loaded normal buffers (e.g. recently visited files in session)
              get_bufnrs = function()
                return vim.tbl_filter(function(buf)
                  return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == ""
                end, vim.api.nvim_list_bufs())
              end,
            },
          },
          ripgrep = {
            module = "blink-ripgrep",
            name = "Ripgrep",
            score_offset = -6,
            opts = {
              prefix_min_len = 3,
              project_root_marker = ".git",
              backend = {
                use = "gitgrep-or-ripgrep",
              },
            },
          },
        },
      },
    },
  },
}
