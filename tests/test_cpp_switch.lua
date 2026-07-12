-- Regression test script for cpp_switch module
local uv = vim.uv or vim.loop
local fs = vim.fs

-- Get the directory of this test script
local script_path = debug.getinfo(1).source:sub(2)
local test_dir = vim.fn.fnamemodify(script_path, ":p:h")
local config_root = vim.fn.fnamemodify(test_dir, ":h")
local base_dir = fs.normalize(test_dir .. "/mock_project_test")

-- Helper to make dirs
local function mkdir_p(path)
  local parts = {}
  for part in path:gmatch("[^/\\]+") do
    table.insert(parts, part)
  end
  local current = ""
  if path:sub(2, 2) == ":" then
    current = parts[1] .. "/"
    table.remove(parts, 1)
  end
  for _, part in ipairs(parts) do
    current = current .. part .. "/"
    uv.fs_mkdir(current, 511)
  end
end

-- Helper to create empty file
local function touch(path)
  local dir = vim.fn.fnamemodify(path, ":h")
  mkdir_p(dir)
  local fd = assert(uv.fs_open(path, "w", 438))
  uv.fs_close(fd)
end

-- Mock various casing and suffix layouts
local files_to_create = {
  -- 1. CamelCase Suffixes
  base_dir .. "/CamelCaseUnit/fooImpl.cpp",
  base_dir .. "/CamelCaseUnit/include/CamelCaseUnit/foo.h",
  
  -- 2. Capitalized / UpperCase Folders
  base_dir .. "/CapitalUnit/Src/bar.cpp",
  base_dir .. "/CapitalUnit/Include/bar.h",
  
  -- 3. Nested layout from user project
  base_dir .. "/app_src/src/data_pipeline/src/meta_record.cpp",
  base_dir .. "/app_src/src/data_pipeline/include/data_pipeline/meta_record.h",
}

for _, f in ipairs(files_to_create) do
  touch(f)
end

-- Set package path relatively and load module
package.path = package.path .. ";" .. fs.normalize(config_root .. "/lua/?.lua")
package.loaded["utils.cpp_switch"] = nil
local cpp_switch = require("utils.cpp_switch")

local function test(source_file, expected_target)
  local alts = cpp_switch.find_all_alternates(source_file)
  local found_match = false
  for _, alt in ipairs(alts) do
    if fs.normalize(alt):lower() == fs.normalize(expected_target):lower() then
      found_match = true
      break
    end
  end
  if found_match then
    print("PASS: " .. vim.fn.fnamemodify(source_file, ":t") .. " -> " .. vim.fn.fnamemodify(expected_target, ":t"))
  else
    print("FAIL: " .. vim.fn.fnamemodify(source_file, ":t") .. " -> " .. vim.fn.fnamemodify(expected_target, ":t"))
    print("  Got alternates: " .. vim.inspect(alts))
    os.exit(1)
  end
end

print("Starting cpp_switch regression tests...")
test(base_dir .. "/CamelCaseUnit/fooImpl.cpp", base_dir .. "/CamelCaseUnit/include/CamelCaseUnit/foo.h")
test(base_dir .. "/CamelCaseUnit/include/CamelCaseUnit/foo.h", base_dir .. "/CamelCaseUnit/fooImpl.cpp")

test(base_dir .. "/CapitalUnit/Src/bar.cpp", base_dir .. "/CapitalUnit/Include/bar.h")
test(base_dir .. "/CapitalUnit/Include/bar.h", base_dir .. "/CapitalUnit/Src/bar.cpp")

test(base_dir .. "/app_src/src/data_pipeline/src/meta_record.cpp", base_dir .. "/app_src/src/data_pipeline/include/data_pipeline/meta_record.h")
test(base_dir .. "/app_src/src/data_pipeline/include/data_pipeline/meta_record.h", base_dir .. "/app_src/src/data_pipeline/src/meta_record.cpp")

-- Clean up
local function rm_rf(path)
  local stat = uv.fs_stat(path)
  if not stat then return end
  if stat.type == "directory" then
    for name, type in vim.fs.dir(path) do
      rm_rf(path .. "/" .. name)
    end
    uv.fs_rmdir(path)
  else
    uv.fs_unlink(path)
  end
end

rm_rf(base_dir)
print("All regression tests passed successfully!")
