-- Helper to dynamically find Node.js >= 22 in fnm without overriding the global 32-bit Node default
local function get_copilot_node()
  local fnm_versions = (vim.env.APPDATA or "") .. "/fnm/node-versions"
  local matches = vim.fn.glob(fnm_versions .. "/v22*/installation/node.exe", false, true)
  if #matches > 0 then
    return vim.fs.normalize(matches[#matches])
  end
  local higher = vim.fn.glob(fnm_versions .. "/v[2-9][0-9]*/installation/node.exe", false, true)
  if #higher > 0 then
    return vim.fs.normalize(higher[#higher])
  end
  return "node"
end

return {
  -- 1) Inline Ghost-Text Suggestions
  {
    "zbirenbaum/copilot.lua",
    lazy = true,
    cmd = "Copilot",
    opts = {
      copilot_node_command = get_copilot_node(),
      suggestion = {
        enabled = true,
        auto_trigger = false, -- OFF by default: only active when toggled or requested
        hide_during_completion = true,
        debounce = 75,
        keymap = {
          accept = "<M-l>", -- Alt-l to accept full suggestion
          accept_word = "<M-w>", -- Alt-w to accept next word only
          accept_line = "<M-j>", -- Alt-j to accept next line only
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = { enabled = false },
    },
    keys = {
      {
        "<leader>at",
        function()
          local suggestion = require("copilot.suggestion")
          suggestion.toggle_auto_trigger()
          local is_on = vim.b.copilot_suggestion_auto_trigger
          vim.notify(
            "Copilot auto-suggestions: " .. (is_on and "ON" or "OFF"),
            vim.log.levels.INFO,
            { title = "Copilot" }
          )
        end,
        desc = "Toggle Copilot Auto-Trigger",
      },
      {
        "<M-\\>",
        function()
          require("copilot.suggestion").next()
        end,
        mode = "i",
        desc = "Trigger Copilot Suggestion",
      },
    },
  },

  -- 2) Copilot Chat & Agentic editing
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    lazy = true,
    cmd = "CopilotChat",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    opts = {
      window = {
        layout = "vertical",
        width = 0.4,
      },
    },
    keys = {
      { "<leader>ac", "<cmd>CopilotChatToggle<cr>", desc = "Toggle Copilot Chat" },
      { "<leader>ae", "<cmd>CopilotChatExplain<cr>", desc = "Explain Code", mode = { "n", "v" } },
      { "<leader>ar", "<cmd>CopilotChatReview<cr>", desc = "Review Code", mode = { "n", "v" } },
      { "<leader>ad", "<cmd>CopilotChatDocs<cr>", desc = "Generate Docs", mode = { "n", "v" } },
    },
  },
}
