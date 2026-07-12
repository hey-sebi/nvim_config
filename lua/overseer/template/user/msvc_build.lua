local fs = vim.fs

--- Detects which build script backend is available in the current project root.
--- @return table|nil # An object describing the backend type, path, and root path.
local function detect_backend()
  local root = vim.fs.root(0, { ".git", ".neoconf.json" }) or vim.uv.cwd()

  -- 1. Try to find build.ps1 (new setup)
  local ps1_matches = vim.fs.find("build.ps1", {
    path = root,
    upward = false,
    type = "file",
  })
  for _, match in ipairs(ps1_matches) do
    local parent = vim.fn.fnamemodify(match, ":h:t"):lower()
    if parent == "scripts" or parent == "script" then
      return {
        type = "ps1",
        path = fs.normalize(match),
        root = root,
      }
    end
  end

  -- 2. Try to find .vscode/build.bat (legacy setup)
  local bat_matches = vim.fs.find("build.bat", {
    path = root,
    upward = false,
    type = "file",
  })
  for _, match in ipairs(bat_matches) do
    local parent = vim.fn.fnamemodify(match, ":h:t"):lower()
    if parent == ".vscode" then
      return {
        type = "bat",
        path = fs.normalize(match),
        root = root,
      }
    end
  end

  return nil
end

--- Get command and cwd configured for the specific backend.
--- @param backend table
--- @param task_type string "build" | "configure" | "clean-configure" | "test"
--- @param preset string "Debug" | "Release" | "RelWithDebInfo"
--- @param extra_args string|nil target name (e.g. "all")
--- @return table|nil
local function get_task_command(backend, task_type, preset, extra_args)
  if backend.type == "ps1" then
    local ps_preset = "msvc-x64_x86-" .. preset:lower()
    if task_type == "build" then
      return {
        cmd = {
          "powershell",
          "-NoProfile",
          "-ExecutionPolicy",
          "Bypass",
          "-File",
          backend.path,
          "-Action",
          "--build",
          "-Preset",
          ps_preset,
          "-ExtraArgs",
          extra_args or "all",
        },
      }
    elseif task_type == "configure" then
      return {
        cmd = {
          "powershell",
          "-NoProfile",
          "-ExecutionPolicy",
          "Bypass",
          "-File",
          backend.path,
          "-Action",
          "--configure",
          "-Preset",
          ps_preset,
        },
      }
    elseif task_type == "clean-configure" then
      return {
        cmd = {
          "powershell",
          "-NoProfile",
          "-ExecutionPolicy",
          "Bypass",
          "-File",
          backend.path,
          "-Action",
          "--clean-configure",
          "-Preset",
          ps_preset,
        },
      }
    elseif task_type == "test" then
      return {
        cmd = {
          "powershell",
          "-NoProfile",
          "-ExecutionPolicy",
          "Bypass",
          "-File",
          backend.path,
          "-Action",
          "--test",
          "-Preset",
          ps_preset,
        },
      }
    end
  elseif backend.type == "bat" then
    if task_type == "build" then
      return {
        cmd = { backend.path, "msvc", "x64_x86", preset, extra_args or "all" },
      }
    elseif task_type == "configure" then
      return {
        cmd = { backend.path, "msvc", "x64_x86", preset, "none" },
      }
    elseif task_type == "clean-configure" then
      return {
        cmd = { backend.path, "msvc", "x64_x86", preset, "clean" },
      }
    elseif task_type == "test" then
      return {
        cmd = { "ctest", "--output-on-failure" },
        cwd = fs.joinpath(backend.root, "build"),
      }
    end
  end
  return nil
end

return {
  generator = function(opts, cb)
    local backend = detect_backend()
    if not backend then
      cb({})
      return
    end

    local errorformat = "%f(%l): %trror %m,%f(%l): %twarning %m"
    local components = {
      { "on_output_quickfix", open = false, set_diagnostics = true },
      "default",
    }

    local templates = {
      -- 1. Build templates
      {
        name = "MSVC: Build (RelWithDebInfo)",
        builder = function()
          local config = get_task_command(backend, "build", "RelWithDebInfo", "all")
          return {
            cmd = config.cmd,
            cwd = config.cwd,
            errorformat = errorformat,
            components = components,
          }
        end,
      },
      {
        name = "MSVC: Build (Debug)",
        builder = function()
          local config = get_task_command(backend, "build", "Debug", "all")
          return {
            cmd = config.cmd,
            cwd = config.cwd,
            errorformat = errorformat,
            components = components,
          }
        end,
      },
      {
        name = "MSVC: Build (Release)",
        builder = function()
          local config = get_task_command(backend, "build", "Release", "all")
          return {
            cmd = config.cmd,
            cwd = config.cwd,
            errorformat = errorformat,
            components = components,
          }
        end,
      },

      -- 2. Configure templates
      {
        name = "MSVC: Configure (RelWithDebInfo)",
        builder = function()
          local config = get_task_command(backend, "configure", "RelWithDebInfo")
          return {
            cmd = config.cmd,
            cwd = config.cwd,
            errorformat = errorformat,
            components = components,
          }
        end,
      },
      {
        name = "MSVC: Clean Configure (RelWithDebInfo)",
        builder = function()
          local config = get_task_command(backend, "clean-configure", "RelWithDebInfo")
          return {
            cmd = config.cmd,
            cwd = config.cwd,
            errorformat = errorformat,
            components = components,
          }
        end,
      },

      -- 3. Test templates
      {
        name = "MSVC: Run Unit Tests (RelWithDebInfo)",
        builder = function()
          local config = get_task_command(backend, "test", "RelWithDebInfo")
          return {
            cmd = config.cmd,
            cwd = config.cwd,
            errorformat = errorformat,
            components = components,
          }
        end,
      },

      -- 4. Custom parameter prompt
      {
        name = "MSVC: Custom Task...",
        params = {
          action = {
            type = "enum",
            choices = { "build", "configure", "clean-configure", "test" },
          },
          preset = {
            type = "enum",
            choices = { "RelWithDebInfo", "Debug", "Release" },
            default = "RelWithDebInfo",
          },
          extra_args = {
            type = "string",
            default = "all",
          },
        },
        builder = function(params)
          local config = get_task_command(backend, params.action, params.preset, params.extra_args)
          return {
            cmd = config.cmd,
            cwd = config.cwd,
            errorformat = errorformat,
            components = components,
          }
        end,
      },
    }

    cb(templates)
  end,
}
