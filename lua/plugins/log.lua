return {
  -- High quality log file highlighting (equivalent to VSCode's log highlighter)
  {
    "fei6409/log-highlight.nvim",
    event = { "BufRead", "BufNewFile" },
    opts = {},
  },
}
