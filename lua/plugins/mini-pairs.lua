return {
  "nvim-mini/mini.pairs",
  enabled = true,
  version = false,
  -- disable built-in autopairs first
  dependencies = { { "windwp/nvim-autopairs", enabled = false } },
  opts = {
    -- Insert mode only; simple rules; very little "surprise" behavior.
    modes = { insert = true, command = false, terminal = false },
    -- Re-map quotes so they DO NOT pair when the next char is alphanumeric.
    -- This prevents the ""SOME TEXT case when you insert at the start.
    mappings = {
      ['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^\\][^%w]" },
      ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%a\\][^%w]" },
      ["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^\\][^%w]" },

      -- Optional: German quotes (multi-byte pairs are supported).
      ["„"] = { action = "open", pair = "„“", neigh_pattern = "[^\\]." },
      ["“"] = { action = "close", pair = "„“", neigh_pattern = "[^\\]." },
    },
  },
}
