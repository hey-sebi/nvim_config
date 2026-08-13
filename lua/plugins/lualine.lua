return {
  {
    "nvim-lualine/lualine.nvim",
    cond = not vim.g.vscode,
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      --- @return string
      local function follow_indicator()
        return vim.b.follow_mode_enabled and "FOLLOW" or ""
      end

      -- Prepend custom items. Note: Lualine renders them in the order inserted.
      local custom_components = {
        { "encoding" },
        { "fileformat" },
        {
          follow_indicator,
          color = { fg = "#7aa2f7" },
        },
      }

      for i, comp in ipairs(custom_components) do
        table.insert(opts.sections.lualine_x, i, comp)
      end
    end,
  },
}
