return {
  -- Disable Noice in VSCode as it causes UI artifacts and VSCode handles messages/cmdline
  {
    "folke/noice.nvim",
    optional = true,
    cond = not vim.g.vscode,
  },
  -- Disable certain Snacks features that cause UI artifacts in VSCode
  {
    "folke/snacks.nvim",
    optional = true,
    opts = function(_, opts)
      if vim.g.vscode then
        opts.scroll = { enabled = false }
        opts.statuscolumn = { enabled = false }
        opts.dashboard = { enabled = false }
        opts.notifier = { enabled = false }
        opts.scope = { enabled = false }
        opts.input = { enabled = false }
      end
    end,
  },
}
