-- Contains customizations and overrides for snacks
return {
  {
    "folke/snacks.nvim",

    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.win = opts.picker.win or {}
      opts.picker.win.input = opts.picker.win.input or {}
      opts.picker.win.input.keys = opts.picker.win.input.keys or {}

      -- Send picker items to quickfix
      opts.picker.win.input.keys["<M-q>"] = { "qflist", mode = { "i", "n" } }
    end,

    -- Disable the default mapping first, then add yours
    keys = {
      -- Disable original keybinding. Important: same mode as upstream (normal)
      { "<leader><leader>", false },
      -- Set override keybinding
      {
        "<leader><leader>",
        function()
          require("snacks").picker.buffers()
        end,
        desc = "Buffers",
      },

      -- Always show and hide the same terminal instance
      {
        "<leader>tt",
        function()
          local Snacks = require("snacks")
          -- 'main' is an arbitrary id; pick any string/number you like
          Snacks.terminal.toggle(nil, { id = "main" })
        end,
        mode = "n",
        desc = "Terminal: toggle main",
      },
    },
  },
}
