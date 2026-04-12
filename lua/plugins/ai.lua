--- Helper function to abstract building the gemini launch command.
local function get_acp_command()
  local is_win = vim.fn.has("win32") == 1
  if not is_win then
    return "gemini", { "--acp" }
  end

  -- 1. Find node.exe
  local node_exe = vim.fn.exepath("node")

  -- 2. Find the gemini.js entry point in your pnpm global folder
  local pnpm_root = vim.fn.trim(vim.fn.system("pnpm root -g"))
  local pnpm_js = pnpm_root .. "/@google/gemini-cli/dist/index.js"

  -- 3. If we found the JS file, we spawn node directly
  if vim.fn.filereadable(pnpm_js) == 1 then
    return node_exe, { pnpm_js, "--acp" }
  end

  -- 4. Last ditch effort: Use the absolute path to cmd.exe to wrap the .cmd
  return "cmd.exe", { "/s", "/c", "gemini", "--acp" }
end

local acp_cmd, acp_args = get_acp_command()

return {
  {
    "carlos-algms/agentic.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    opts = {
      provider = "gemini-acp",
      acp_providers = {
        ["gemini-acp"] = {
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
