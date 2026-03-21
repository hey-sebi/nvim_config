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

      --- Adds an "alternate file exists" indicator (currently only for C++)
      --- @return string
      local function alt_indicator()
        -- Robust loading of our utility
        local ok, cpp_switch = pcall(require, "utils.cpp_switch")
        if not ok then
          return ""
        end

        if vim.bo.buftype ~= "" then
          return ""
        end
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname == "" then
          return ""
        end

        -- Manual check (must be fast for statusline)
        local alternates = cpp_switch.find_all_alternates(bufname)
        return #alternates > 0 and "󰈔 Alt" or ""
      end

      -- Prepend custom items. Note: Lualine renders them in the order inserted.
      local custom_components = {
        { "encoding" },
        { "fileformat" },
        {
          follow_indicator,
          color = { fg = "#7aa2f7" },
        },
        {
          alt_indicator,
          color = { fg = "#ff9e64", gui = "bold" },
          on_click = function()
            local ok, cpp_switch = pcall(require, "utils.cpp_switch")
            if ok then
              cpp_switch.switch_smart()
            end
          end,
        },
      }

      for i, comp in ipairs(custom_components) do
        table.insert(opts.sections.lualine_x, i, comp)
      end
    end,
  },
}
