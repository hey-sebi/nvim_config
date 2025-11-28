return {
  {
    "LazyVim/LazyVim",
    keys = {
      -- Exit terminal insert mode
      {
        "<C-x>",
        [[<C-\><C-n>]],
        mode = "t",
        desc = "Exit terminal insert mode",
      },
      -- Terminal split navigation
      { "<C-h>", [[<C-\><C-n><C-w>h]], mode = "t", desc = "Terminal: window left" },
      { "<C-j>", [[<C-\><C-n><C-w>j]], mode = "t", desc = "Terminal: window down" },
      { "<C-k>", [[<C-\><C-n><C-w>k]], mode = "t", desc = "Terminal: window up" },
      { "<C-l>", [[<C-\><C-n><C-w>l]], mode = "t", desc = "Terminal: window right" },
    },
  },
}

