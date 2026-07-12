return {
  generator = function(opts, cb)
    local build_script = "scripts/build.ps1"
    local root = vim.fs.root(0, { ".git", ".neoconf.json" }) or vim.uv.cwd()
    local matches = vim.fs.find("build.ps1", {
      path = root,
      upward = false,
      type = "file",
    })
    for _, match in ipairs(matches) do
      local parent = vim.fn.fnamemodify(match, ":h:t"):lower()
      if parent == "scripts" or parent == "script" then
        build_script = vim.fs.normalize(match)
        break
      end
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
          return {
            cmd = { "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", build_script, "-Action", "--build", "-Preset", "msvc-x64_x86-relwithdebinfo", "-ExtraArgs", "all" },
            errorformat = errorformat,
            components = components,
          }
        end,
      },
      {
        name = "MSVC: Build (Debug)",
        builder = function()
          return {
            cmd = { "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", build_script, "-Action", "--build", "-Preset", "msvc-x64_x86-debug", "-ExtraArgs", "all" },
            errorformat = errorformat,
            components = components,
          }
        end,
      },
      {
        name = "MSVC: Build (Release)",
        builder = function()
          return {
            cmd = { "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", build_script, "-Action", "--build", "-Preset", "msvc-x64_x86-release", "-ExtraArgs", "all" },
            errorformat = errorformat,
            components = components,
          }
        end,
      },

      -- 2. Configure templates
      {
        name = "MSVC: Configure (RelWithDebInfo)",
        builder = function()
          return {
            cmd = { "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", build_script, "-Action", "--configure", "-Preset", "msvc-x64_x86-relwithdebinfo" },
            errorformat = errorformat,
            components = components,
          }
        end,
      },
      {
        name = "MSVC: Clean Configure (RelWithDebInfo)",
        builder = function()
          return {
            cmd = { "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", build_script, "-Action", "--clean-configure", "-Preset", "msvc-x64_x86-relwithdebinfo" },
            errorformat = errorformat,
            components = components,
          }
        end,
      },

      -- 3. Test templates
      {
        name = "MSVC: Run Unit Tests (RelWithDebInfo)",
        builder = function()
          return {
            cmd = { "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", build_script, "-Action", "--test", "-Preset", "msvc-x64_x86-relwithdebinfo" },
            errorformat = errorformat,
            components = components,
          }
        end,
      },

      -- 4. Custom parameter prompt fallback
      {
        name = "MSVC: Custom Task...",
        params = {
          action = {
            type = "enum",
            choices = { "build", "configure", "clean-configure", "test" },
          },
          preset = {
            type = "enum",
            choices = {
              "msvc-x64_x86-relwithdebinfo",
              "msvc-x64_x86-debug",
              "msvc-x64_x86-release",
            },
            default = "msvc-x64_x86-relwithdebinfo",
          },
          extra_args = {
            type = "string",
            default = "all",
          },
        },
        builder = function(params)
          local cmd = {
            "powershell",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            build_script,
            "-Action",
            "--" .. params.action,
            "-Preset",
            params.preset,
          }
          if params.extra_args and params.extra_args ~= "" then
            table.insert(cmd, "-ExtraArgs")
            table.insert(cmd, params.extra_args)
          end
          return {
            cmd = cmd,
            errorformat = errorformat,
            components = components,
          }
        end,
      },
    }

    cb(templates)
  end,
}
