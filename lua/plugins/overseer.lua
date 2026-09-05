return {
  "stevearc/overseer.nvim",
  cond = not vim.g.vscode,

  -- ----------------------------------------------------------------
  -- Behavior customization
  -- ----------------------------------------------------------------
  opts = function(_, opts)
    opts = opts or {}
    opts.disable_template_modules = {
      "overseer.template.vscode",
      "^.*vscode",
    }
    opts.templates = {
      "builtin.cargo",
      "builtin.make",
      "builtin.just",
      "builtin.npm",
      "builtin.shell",
      "user.msvc_build",
    }
    opts.component_aliases = opts.component_aliases or {}

    -- Default components applied to all tasks (adds on_start_notify for UI feedback on launch)
    opts.component_aliases.default = {
      "on_exit_set_status",
      "on_complete_notify",
      { "on_complete_dispose", require_view = { "SUCCESS", "FAILURE" } },
      "on_start_notify",
    }

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
      "<leader>oo",
      "<cmd>OverseerRun<cr>",
      desc = "Run task",
    },
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
        local overseer = require("overseer")
        local tasks = overseer.list_tasks({ recent_first = true })
        if vim.tbl_isempty(tasks) then
          vim.notify("No Overseer task found", vim.log.levels.WARN)
          return
        end

        local task = tasks[1]
        if task:is_disposed() then
          vim.notify("Last Overseer task was disposed", vim.log.levels.WARN)
          return
        end

        local bufnr = task:get_bufnr()
        if not bufnr or bufnr == 0 then
          vim.notify("Last task has no output buffer", vim.log.levels.WARN)
          return
        end

        -- Check if a floating window is already displaying this buffer
        local float_win = nil
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == bufnr then
            local config = vim.api.nvim_win_get_config(win)
            if config.relative and config.relative ~= "" then
              float_win = win
              break
            end
          end
        end

        if float_win then
          pcall(vim.api.nvim_win_close, float_win, true)
        else
          task:open_output("float")
        end
      end,
      desc = "Toggle last task output float",
    },
  },
}
