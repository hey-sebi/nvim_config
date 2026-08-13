local function neogit_submodule_picker()
  local git_root = vim.fs.root(0, { ".git", ".gitmodules" })
  if not git_root then
    vim.notify("Not in a git repository", vim.log.levels.WARN, { title = "Git Submodules" })
    return
  end

  local gitmodules_files = vim.fs.find(".gitmodules", {
    path = git_root,
    upward = false,
    limit = math.huge,
  })

  if #gitmodules_files == 0 then
    vim.notify("No .gitmodules files found", vim.log.levels.INFO, { title = "Git Submodules" })
    return
  end

  local items = {}
  local seen = {}

  for _, gm_path in ipairs(gitmodules_files) do
    local norm_gm = vim.fs.normalize(gm_path)
    -- Skip .gitmodules located inside .git, node_modules, build, out folders
    if not norm_gm:find("/%.git/") and not norm_gm:find("/node_modules/") and not norm_gm:find("/build/") and not norm_gm:find("/out/") then
      local base_dir = vim.fs.dirname(norm_gm)
      local f = io.open(norm_gm, "r")
      if f then
        for line in f:lines() do
          local path = line:match("^%s*path%s*=%s*(.-)%s*$")
          if path and path ~= "" then
            local abs_path = vim.fs.normalize(base_dir .. "/" .. path)
            if not seen[abs_path] and vim.uv.fs_stat(abs_path) then
              seen[abs_path] = true
              local rel_path = vim.fn.fnamemodify(abs_path, ":.")
              if rel_path:sub(1, 2) == "./" then
                rel_path = rel_path:sub(3)
              end
              table.insert(items, {
                text = rel_path,
                file = abs_path,
              })
            end
          end
        end
        f:close()
      end
    end
  end

  if #items == 0 then
    vim.notify("No git submodules found in .gitmodules", vim.log.levels.INFO, { title = "Git Submodules" })
    return
  end

  table.sort(items, function(a, b)
    return a.text < b.text
  end)

  require("snacks").picker({
    prompt = "Git Submodules",
    items = items,
    format = "file",
    confirm = function(picker, item)
      picker:close()
      if item and item.file then
        vim.cmd("Neogit cwd=" .. vim.fn.fnameescape(item.file))
      end
    end,
  })
end

return {
  -- Diffview
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    opts = {},
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
    },
  },

  -- Neogit
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    cmd = { "Neogit" },
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit Status (Tab)" },
      { "<leader>gG", "<cmd>Neogit kind=floating<cr>", desc = "Neogit Status (Float)" },
      {
        "<leader>gm",
        neogit_submodule_picker,
        desc = "Neogit Submodule Picker",
      },
    },
    opts = {
      disable_commit_confirmation = true,
      status = {
        show_untracked_files = "normal", -- Collapses untracked directories instead of listing thousands of sub-files
      },
      integrations = {
        -- Enables integration with diffview.nvim for diffing
        diffview = true,
      },
    },
  },
}

