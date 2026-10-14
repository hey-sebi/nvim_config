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

  -- 2. Try to find build.bat (legacy setup in scripts/, script/, .vscode/, or root)
  local bat_matches = vim.fs.find("build.bat", {
    path = root,
    upward = false,
    type = "file",
  })
  for _, match in ipairs(bat_matches) do
    local parent = vim.fn.fnamemodify(match, ":h:t"):lower()
    if parent == ".vscode" or parent == "scripts" or parent == "script" or fs.normalize(match) == fs.normalize(fs.joinpath(root, "build.bat")) then
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
--- @param task_type string "fast-build" | "build" | "configure" | "clean-configure" | "test"
--- @param preset string "Debug" | "Release" | "RelWithDebInfo"
--- @param extra_args string|nil target name and optional ninja flags (e.g. "all -j4", "foo -j4")
--- @return table|nil
local function get_task_command(backend, task_type, preset, extra_args)
  local ninja_args = extra_args or "all -j4"
  if backend.type == "ps1" then
    local ps_preset = "msvc-x64_x86-" .. preset:lower()
    if task_type == "build" or task_type == "fast-build" then
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
          ninja_args,
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
    if task_type == "fast-build" then
      -- Uses "skip-config" to directly invoke Ninja without re-running CMake configuration
      return {
        cmd = { backend.path, "skip-config", "x64_x86", ninja_args },
        cwd = backend.root,
      }
    elseif task_type == "build" then
      return {
        cmd = { backend.path, "msvc", "x64_x86", preset, ninja_args },
        cwd = backend.root,
      }
    elseif task_type == "configure" then
      return {
        cmd = { backend.path, "msvc", "x64_x86", preset, "none" },
        cwd = backend.root,
      }
    elseif task_type == "clean-configure" then
      return {
        cmd = { backend.path, "msvc", "x64_x86", preset, "clean" },
        cwd = backend.root,
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
      -- 1. Fast build target with Ninja (skips CMake config, limits CPU via -j4)
      {
        name = "MSVC: Fast Build Target (Ninja -j4)",
        desc = "Fast Ninja build (skips CMake config), e.g. 'foo -j4' or 'all -j4'",
        params = {
          extra_args = {
            type = "string",
            name = "Target & Ninja args",
            default = "all -j4",
            desc = "Target name and flags (e.g. 'foo -j4', 'all -j4')",
            optional = false,
          },
        },
        builder = function(params)
          local args = (params.extra_args and params.extra_args ~= "") and params.extra_args or "all -j4"
          if not args:match("%-j%s*%d+") then
            args = args .. " -j4"
          end
          local config = get_task_command(backend, "fast-build", "RelWithDebInfo", args)
          return {
            cmd = config.cmd,
            cwd = config.cwd,
            errorformat = errorformat,
            components = components,
          }
        end,
      },

      -- 2. Full Build templates (also default to -j4 to prevent pegging 100% CPU)
      {
        name = "MSVC: Build (RelWithDebInfo)",
        builder = function()
          local config = get_task_command(backend, "build", "RelWithDebInfo", "all -j4")
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
          local config = get_task_command(backend, "build", "Debug", "all -j4")
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
          local config = get_task_command(backend, "build", "Release", "all -j4")
          return {
            cmd = config.cmd,
            cwd = config.cwd,
            errorformat = errorformat,
            components = components,
          }
        end,
      },

      -- 3. Configure templates
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

      -- 4. Test templates
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

      -- 5. Custom parameter prompt (with defaults for all fields)
      {
        name = "MSVC: Custom Task...",
        params = {
          action = {
            type = "enum",
            choices = { "fast-build", "build", "configure", "clean-configure", "test" },
            default = "fast-build",
          },
          preset = {
            type = "enum",
            choices = { "RelWithDebInfo", "Debug", "Release" },
            default = "RelWithDebInfo",
          },
          extra_args = {
            type = "string",
            default = "all -j4",
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
