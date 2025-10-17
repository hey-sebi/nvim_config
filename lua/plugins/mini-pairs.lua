return {
  "echasnovski/mini.pairs",
  enabled = true,
  version = false,
  -- disable built-in autopairs first
  dependencies = { { "windwp/nvim-autopairs", enabled = false } },
  opts = {
    -- Insert mode only; simple rules; very little “surprise” behavior.
    modes = { insert = true, command = false, terminal = false },
    mappings = {
      -- Keep quotes paired, but make brackets less eager by requiring whitespace/EOL
      ['"'] = { action = "open", pair = '""', neigh_pattern = "[^%w\\%)]" },
      ["'"] = { action = "open", pair = "''", neigh_pattern = "[^%w\\%)]" },
      ["("] = { action = "open", pair = "()", neigh_pattern = "[%s%)]" },
      ["["] = { action = "open", pair = "[]", neigh_pattern = "[%s%]]" },
      ["{"] = { action = "open", pair = "{}", neigh_pattern = "[%s%}]" },
    },
  },
}
