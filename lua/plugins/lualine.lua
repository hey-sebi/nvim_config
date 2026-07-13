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

      -- Define an autocmd to cache alternate file existence on BufEnter/BufWritePost
      local cpp_group = vim.api.nvim_create_augroup("LualineCppAlt", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
        group = cpp_group,
        pattern = { "*.h", "*.hpp", "*.hh", "*.hxx", "*.cpp", "*.cc", "*.cxx", "*.c" },
        callback = function(event)
          local ok, cpp_switch = pcall(require, "utils.cpp_switch")
          if ok then
            local bufname = vim.api.nvim_buf_get_name(event.buf)
            if bufname ~= "" then
              local alternates = cpp_switch.find_all_alternates(bufname)
              vim.b[event.buf].alternate_file_exists = #alternates > 0
            end
          end
        end,
      })

      --- Adds an "alternate file exists" indicator (reads from cached variable)
      --- @return string
      local function alt_indicator()
        if vim.b.alternate_file_exists then
          return "󰈔 Alt"
        end
        return ""
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
