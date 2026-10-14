return {
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}

      -- 1) Use underline indicator for the active buffer across full width
      opts.options.indicator = {
        style = "underline",
      }

      -- 2) Display more characters and enforce reasonable tab size
      opts.options.max_name_length = 26
      opts.options.tab_size = 26

      -- 3) Override truncate_name so that the file extension (.cpp, .h, etc.)
      --    is ALWAYS preserved when a filename exceeds the limit (e.g. "my_long_class_… .cpp")
      local utils = require("bufferline.utils")
      local constants = require("bufferline.constants")
      utils.truncate_name = function(name, word_limit)
        if vim.api.nvim_strwidth(name) <= word_limit then
          return name
        end
        local ext = vim.fn.fnamemodify(name, ":e")
        if ext ~= "" and ext:match("^%w+$") then
          local suffix = "." .. ext
          local suffix_len = vim.api.nvim_strwidth(suffix)
          local ellipsis_len = vim.api.nvim_strwidth(constants.ELLIPSIS)
          local avail = word_limit - suffix_len - ellipsis_len
          if avail >= 3 then
            local base = vim.fn.fnamemodify(name, ":r")
            local short_base = vim.fn.strcharpart(base, 0, avail)
            return short_base .. constants.ELLIPSIS .. suffix
          end
        end
        return vim.fn.strcharpart(name, 0, word_limit - 1) .. constants.ELLIPSIS
      end

      -- 4) Custom highlights: keep filename text in normal buffer colors,
      --    so tabs don't turn red even when clang-tidy/LSP reports errors.
      --    (The diagnostic badge like ' 3' remains colored via error_diagnostic).
      local prev_highlights = opts.highlights
      opts.highlights = function()
        local hls = {}
        if type(prev_highlights) == "function" then
          hls = prev_highlights() or {}
        elseif type(prev_highlights) == "table" then
          hls = vim.deepcopy(prev_highlights)
        end

        -- Inherit standard theme colors for filename text in error/warning states:
        -- - Normal fg (bright active text) -> for error_selected and warning_selected
        -- - Comment fg (dim inactive text) -> for error and warning
        -- - LineNr fg (subtle visible text) -> for error_visible and warning_visible
        local active_fg = { attribute = "fg", highlight = "Normal" }
        local inactive_fg = { attribute = "fg", highlight = "Comment" }
        local visible_fg = { attribute = "fg", highlight = "LineNr" }

        hls.error = vim.tbl_extend("force", hls.error or {}, { fg = inactive_fg })
        hls.error_visible = vim.tbl_extend("force", hls.error_visible or {}, { fg = visible_fg })
        hls.error_selected = vim.tbl_extend("force", hls.error_selected or {}, { fg = active_fg })

        hls.warning = vim.tbl_extend("force", hls.warning or {}, { fg = inactive_fg })
        hls.warning_visible = vim.tbl_extend("force", hls.warning_visible or {}, { fg = visible_fg })
        hls.warning_selected = vim.tbl_extend("force", hls.warning_selected or {}, { fg = active_fg })

        return hls
      end
    end,
  },
}
