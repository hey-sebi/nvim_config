return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Ensure tables exist
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      -- Add encoding and filetype (and optionally fileformat) on the right side
      -- Common components:
      --   "encoding"   -> file encoding (utf-8, latin1, ...)
      --   "fileformat" -> line endings (unix, dos, mac)
      --   "filetype"   -> ft (cpp, python, ...)
      table.insert(opts.sections.lualine_x, 1, "encoding")
      table.insert(opts.sections.lualine_x, 2, "fileformat")
      table.insert(opts.sections.lualine_x, 3, {
        "filetype",
        icon = true,
        -- Set to true: only show the icon
        -- set to false: show "cpp", "python", etc.
        icon_only = false,
      })
    end,
  },
}
