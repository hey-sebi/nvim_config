local fs = vim.fs

--- Find root containing CMakePresets.json or CMakeUserPresets.json and parse available presets.
--- @return table|nil # Info about presets, or nil if not a CMake presets project.
local function get_presets_info()
  local root = vim.fs.root(0, { "CMakePresets.json", "CMakeUserPresets.json" }) or vim.uv.cwd()
  local files = { "CMakePresets.json", "CMakeUserPresets.json" }
  local configure_presets = {}
  local build_presets = {}
  local test_presets = {}
  local found = false

  for _, fname in ipairs(files) do
    local fpath = fs.joinpath(root, fname)
    if vim.fn.filereadable(fpath) == 1 then
      found = true
      local ok, lines = pcall(vim.fn.readfile, fpath)
      if ok and lines then
        local json_ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
        if json_ok and type(data) == "table" then
          for _, p in ipairs(data.configurePresets or {}) do
            if not p.hidden and p.name and not vim.tbl_contains(configure_presets, p.name) then
              table.insert(configure_presets, p.name)
            end
          end
          for _, p in ipairs(data.buildPresets or {}) do
            if not p.hidden and p.name and not vim.tbl_contains(build_presets, p.name) then
              table.insert(build_presets, p.name)
            end
          end
          for _, p in ipairs(data.testPresets or {}) do
            if not p.hidden and p.name and not vim.tbl_contains(test_presets, p.name) then
              table.insert(test_presets, p.name)
            end
          end
        end
      end
    end
  end

  if not found or (#configure_presets == 0 and #build_presets == 0) then
    return nil
  end

  -- Determine default preset names: prefer "default", then first available
  local default_build = "default"
  if not vim.tbl_contains(build_presets, default_build) then
    default_build = build_presets[1] or "default"
  end

  local default_configure = "default"
  if not vim.tbl_contains(configure_presets, default_configure) then
    default_configure = configure_presets[1] or "default"
  end

  local default_test = "default"
  if not vim.tbl_contains(test_presets, default_test) then
    default_test = test_presets[1] or "default"
  end

  return {
    root = root,
    configure_presets = configure_presets,
    build_presets = build_presets,
    test_presets = test_presets,
    default_build = default_build,
    default_configure = default_configure,
    default_test = default_test,
  }
end

return {
  generator = function(opts, cb)
    local info = get_presets_info()
    if not info then
      cb({})
      return
    end

    local errorformat = table.concat({
      "%f(%l): %trror %m",
      "%f(%l): %twarning %m",
      "%f:%l:%c: %trror: %m",
      "%f:%l:%c: %twarning: %m",
      "%f:%l: %trror: %m",
      "%f:%l: %twarning: %m",
      "ninja: error: %m",
    }, ",")

    local components = {
      { "on_output_quickfix", open = false, set_diagnostics = true },
      "default",
    }

    local templates = {}

    -- 1. Fast build default preset
    table.insert(templates, {
      name = string.format("CMake: Build (%s)", info.default_build),
      desc = string.format("Build preset '%s' (cmake --build --preset %s)", info.default_build, info.default_build),
      builder = function()
        return {
          cmd = { "cmake", "--build", "--preset", info.default_build },
          cwd = info.root,
          errorformat = errorformat,
          components = components,
        }
      end,
    })

    -- 2. Build target or custom flags with preset
    table.insert(templates, {
      name = "CMake: Build Target / Custom...",
      desc = "Build a specific target or pass extra flags with a preset",
      params = {
        preset = {
          type = "enum",
          name = "Build Preset",
          choices = info.build_presets,
          default = info.default_build,
        },
        target = {
          type = "string",
          name = "Target (optional)",
          default = "",
          desc = "Leave empty for all, or specify target name (e.g. pathlens_cli)",
          optional = true,
        },
        extra_args = {
          type = "string",
          name = "Extra flags (optional)",
          default = "",
          desc = "Passed after '--' (e.g. -j4)",
          optional = true,
        },
      },
      builder = function(params)
        local cmd = { "cmake", "--build", "--preset", params.preset }
        if params.target and params.target:match("%S") then
          table.insert(cmd, "--target")
          table.insert(cmd, vim.trim(params.target))
        end
        if params.extra_args and params.extra_args:match("%S") then
          table.insert(cmd, "--")
          for arg in string.gmatch(params.extra_args, "%S+") do
            table.insert(cmd, arg)
          end
        end
        return {
          cmd = cmd,
          cwd = info.root,
          errorformat = errorformat,
          components = components,
        }
      end,
    })

    -- 3. Configure default preset
    table.insert(templates, {
      name = string.format("CMake: Configure (%s)", info.default_configure),
      desc = string.format("Configure preset '%s' (cmake --preset %s)", info.default_configure, info.default_configure),
      builder = function()
        return {
          cmd = { "cmake", "--preset", info.default_configure },
          cwd = info.root,
          errorformat = errorformat,
          components = components,
        }
      end,
    })

    -- 4. Configure custom preset
    table.insert(templates, {
      name = "CMake: Configure Preset...",
      desc = "Select configure preset and options",
      params = {
        preset = {
          type = "enum",
          name = "Configure Preset",
          choices = info.configure_presets,
          default = info.default_configure,
        },
        fresh = {
          type = "boolean",
          name = "Fresh configure (--fresh)",
          default = false,
          desc = "Clear cache and start fresh",
        },
      },
      builder = function(params)
        local cmd = { "cmake", "--preset", params.preset }
        if params.fresh then
          table.insert(cmd, "--fresh")
        end
        return {
          cmd = cmd,
          cwd = info.root,
          errorformat = errorformat,
          components = components,
        }
      end,
    })

    -- 5. Run tests for default preset
    if #info.test_presets > 0 then
      table.insert(templates, {
        name = string.format("CMake: Run Tests (%s)", info.default_test),
        desc = string.format("Run ctest for preset '%s' (ctest --preset %s)", info.default_test, info.default_test),
        builder = function()
          return {
            cmd = { "ctest", "--preset", info.default_test },
            cwd = info.root,
            errorformat = errorformat,
            components = components,
          }
        end,
      })

      table.insert(templates, {
        name = "CMake: Run Tests...",
        desc = "Run ctest with options",
        params = {
          preset = {
            type = "enum",
            name = "Test Preset",
            choices = info.test_presets,
            default = info.default_test,
          },
          extra_args = {
            type = "string",
            name = "CTest args",
            default = "--output-on-failure",
            desc = "e.g. --output-on-failure, --rerun-failed",
            optional = true,
          },
        },
        builder = function(params)
          local cmd = { "ctest", "--preset", params.preset }
          if params.extra_args and params.extra_args:match("%S") then
            for arg in string.gmatch(params.extra_args, "%S+") do
              table.insert(cmd, arg)
            end
          end
          return {
            cmd = cmd,
            cwd = info.root,
            errorformat = errorformat,
            components = components,
          }
        end,
      })
    end

    cb(templates)
  end,
}
