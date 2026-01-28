return {
  "stevearc/overseer.nvim",
  cond = not vim.g.vscode,

  -- ----------------------------------------------------------------
  -- Behavior customization
  -- ----------------------------------------------------------------
  opts = function(_, opts)
    opts = opts or {}
    opts.component_aliases = opts.component_aliases or {}

    -- Tasks coming from .vscode/tasks.json use the "default_vscode" alias
    -- Alternatively: default (instead of default_vscode) will apply this to all
    -- tasks
    opts.component_aliases.default_vscode = {
      "default",
      "on_result_diagnostics",
      {
        "open_output",
        direction = "dock", -- bottom dock next to task list
        on_start = "always", -- open as soon as the task starts
        -- on_complete = "never",
        focus = false, -- focus output or not?
      },
    }

    return opts
  end,

  -- ----------------------------------------------------------------
  -- Keybindings
  -- ----------------------------------------------------------------
  keys = {

    -- ----------------------------------------------------------------
    -- Overrides for LazyVim's defaults because they are outdated
    -- ----------------------------------------------------------------
    -- Replace <leader>oi (old :OverseerInfo) with checkhealth
    {
      "<leader>oi",
      "<cmd>checkhealth overseer<cr>",
      desc = "Overseer health",
    },

    -- Disable <leader>oq, since :OverseerQuickAction no longer exists
    { "<leader>oq", false },

    -- ----------------------------------------------------------------
    -- Additional keybindings
    -- ----------------------------------------------------------------
    {
      "<leader>or",
      function()
        local overseer = require("overseer")

        -- Get recently executed tasks, newest first
        local tasks = overseer.list_tasks({ recent_first = true })
        if vim.tbl_isempty(tasks) then
          vim.notify("No previous Overseer task to rerun", vim.log.levels.WARN)
          return
        end

        local task = tasks[1]

        -- In case task auto-disposal is configured, be defensive
        if task:is_disposed() then
          vim.notify("Last Overseer task was disposed", vim.log.levels.WARN)
          return
        end
        -- Optional: stop running tasks
        local force_stop = false
        task:restart(force_stop)
      end,
      desc = "Rerun last task",
    },
    {
      "<leader>oW",
      function()
        local omo = require("utils.overseer_maximize_output")
        omo.maximize_last_task_output()
      end,
      desc = "Maximize last Overseer task output",
    },
  },
}
