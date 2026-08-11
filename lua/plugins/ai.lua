--- Helper function to abstract building the Antigravity CLI launch command.
local function get_acp_command()
  local agy_bin = vim.fn.exepath("agy")
  if agy_bin ~= "" then
    return agy_bin, { "acp" }
  end

  local antigravity_bin = vim.fn.exepath("antigravity")
  if antigravity_bin ~= "" then
    return antigravity_bin, { "acp" }
  end

  return "agy", { "acp" }
end

local acp_cmd, acp_args = get_acp_command()

return {
  {
    "carlos-algms/agentic.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    opts = {
      provider = "antigravity-acp",
      acp_providers = {
        ["antigravity-acp"] = {
          command = acp_cmd,
          args = acp_args,
        },
      },
      -- Integrated documentation preferences
      instructions = "Always document code. Use Doxygen for C++ and JSDoc/TSDoc for JS/TS.",
    },
    keys = {
      {
        "<leader>aa",
        function()
          require("agentic").toggle()
        end,
        desc = "Toggle Agentic AI",
      },
      {
        "<leader>as",
        function()
          require("agentic").new_session()
        end,
        desc = "New AI Session",
      },
      {
        "<leader>ar",
        function()
          require("agentic").restore_session()
        end,
        desc = "Restore Session",
      },
    },
  },
}

