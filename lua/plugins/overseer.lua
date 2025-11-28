return {
  "stevearc/overseer.nvim",
  opts = {
    strategy = {
      "terminal",
      open_on_start = true, -- show the terminal when task starts
      close_on_exit = false, -- keep it open so you can read output
      auto_scroll = true, -- follow output
    },
  },
}
