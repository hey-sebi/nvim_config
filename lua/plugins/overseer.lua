return {
  "stevearc/overseer.nvim",
  cond = not vim.g.vscode,

  init = function()
    -- Make OverseerForm buffers easy to submit in both normal and insert mode
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "OverseerForm",
      desc = "Easy submit for Overseer parameter forms",
      callback = function(event)
        vim.keymap.set("n", "<CR>", "<cmd>w<cr>", { buffer = event.buf, desc = "Submit form" })
        vim.keymap.set({ "n", "i" }, "<C-s>", "<cmd>w<cr>", { buffer = event.buf, desc = "Submit form" })
      end,
    })
  end,

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
      "user.cmake_presets",
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
    opts.component_aliases.default_vscode = {
      "default",
      "on_result_diagnostics",
      {
        "open_output",
        direction = "dock", -- bottom dock next to task list
        on_start = "always", -- open as soon as the task starts
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
      "<leader>ob",
      function()
        local overseer = require("overseer")
        local root = vim.fs.root(0, { "CMakePresets.json", "CMakeUserPresets.json", ".git" }) or vim.uv.cwd()
        local has_cmake_presets = vim.fn.filereadable(vim.fs.joinpath(root, "CMakePresets.json")) == 1
          or vim.fn.filereadable(vim.fs.joinpath(root, "CMakeUserPresets.json")) == 1

        if has_cmake_presets then
          local last_build = vim.g.overseer_last_cmake_preset or "default"
          vim.ui.input({
            prompt = "CMake Build (preset & optional target): ",
            default = last_build,
          }, function(input)
            if not input or input:match("^%s*$") then
              return
            end
            vim.g.overseer_last_cmake_preset = input

            local parts = vim.split(vim.trim(input), "%s+")
            local preset = parts[1] or "default"
            local target = nil
            local extra = {}

            local i = 2
            while i <= #parts do
              if parts[i] == "--target" and parts[i + 1] then
                target = parts[i + 1]
                i = i + 2
              elseif not target and not parts[i]:match("^%-") then
                target = parts[i]
                i = i + 1
              else
                table.insert(extra, parts[i])
                i = i + 1
              end
            end

            overseer.run_task({
              name = "CMake: Build Target / Custom...",
              params = {
                preset = preset,
                target = target or "",
                extra_args = table.concat(extra, " "),
              },
            }, function(_, err)
              if err then
                vim.notify("Overseer error: " .. tostring(err), vim.log.levels.ERROR)
              end
            end)
          end)
          return
        end

        -- Legacy MSVC project (logos)
        local last_target = vim.g.overseer_last_cmake_target or "all -j4"
        vim.ui.input({
          prompt = "Build target & Ninja args: ",
          default = last_target,
        }, function(input)
          if not input or input:match("^%s*$") then
            return
          end
          vim.g.overseer_last_cmake_target = input

          -- Auto-append -j4 if user didn't specify any -j flag to protect CPU
          local final_args = input
          if not final_args:match("%-j%s*%d+") then
            final_args = final_args .. " -j4"
          end

          overseer.run_task({
            name = "MSVC: Fast Build Target (Ninja -j4)",
            params = { extra_args = final_args },
          }, function(task, err)
            if err then
              vim.notify("Overseer error: " .. tostring(err), vim.log.levels.ERROR)
            end
          end)
        end)
      end,
      desc = "Build project / target",
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
      "<leader>os",
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
