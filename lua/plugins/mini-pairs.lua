return {
  "nvim-mini/mini.pairs",
  event = "VeryLazy",
  opts = function(_, opts)
    -- keep existing opts if any and extend
    opts = opts or {}

    -- Smarter defaults for symmetrical quotes:
    -- - use "closeopen" so typing a quote jumps over an existing one
    -- - neighborhood patterns avoid pairing in the middle of words
    opts.mappings = vim.tbl_deep_extend("force", opts.mappings or {}, {
      ['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^\\]." },
      ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%w\\]." },
      ["`"] = { action = "closeopen", pair = "``", neigh_pattern = ".`" },
    })

    return opts
  end,

  config = function(_, opts)
    local mp = require("mini.pairs")
    mp.setup(opts)

    -- Python: make """ and ''' expand to a proper docstring block.
    -- This triggers only when you actually type three quotes in a row.
    -- Normal single/double quote pairing remains intact.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "python",
      callback = function(ev)
        local function map_triple(lhs, rhs)
          vim.keymap.set("i", lhs, function()
            -- Insert triple quotes, a blank line, closing triple quotes,
            -- and leave cursor on the middle blank line.
            return rhs
          end, {
            buffer = ev.buf,
            expr = true,
            replace_keycodes = true,
            desc = "Insert Python triple-quote docstring block",
          })
        end

        -- """<CR><CR>"""<Up>
        map_triple('"""', '"""<CR><CR>"""<Up>')
        map_triple("'''", "'''<CR><CR>'''<Up>")
      end,
    })
  end,
}
