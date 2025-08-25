-- Contains customizations and overrides for snacks

return {
  {
    "folke/snacks.nvim",
    -- disable the default mapping first, then add yours
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
    },
  },
}
