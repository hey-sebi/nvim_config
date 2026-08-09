local function neogit_submodule_picker()
  local git_root_output = vim.fn.systemlist("git rev-parse --show-toplevel")
  if vim.v.shell_error ~= 0 or #git_root_output == 0 then
    vim.notify("Not in a git repository", vim.log.levels.WARN, { title = "Git Submodules" })
    return
  end
  local git_root = git_root_output[1]

  local lines = vim.fn.systemlist("git submodule status --recursive")
  if vim.v.shell_error ~= 0 or #lines == 0 then
    lines = vim.fn.systemlist("git config --file .gitmodules --get-regexp path")
  end

  local items = {}
  for _, line in ipairs(lines) do
    line = line:gsub("^%s+", "")
    if line ~= "" then
      local path
      if line:match("^[%+%-U%s]?%x+%s+") then
        path = line:match("^[%+%-U%s]?%x+%s+(.-)%s*%(") or line:match("^[%+%-U%s]?%x+%s+(.-)$")
      elseif line:match("^submodule%..*%.path%s+") then
        path = line:match("^submodule%..*%.path%s+(.-)$")
      else
        path = line
      end

      if path and path ~= "" then
        path = vim.trim(path)
        local abs_path = git_root .. "/" .. path
        table.insert(items, {
          text = path,
          file = abs_path,
        })
      end
    end
  end

  if #items == 0 then
    vim.notify("No git submodules found in this repository", vim.log.levels.INFO, { title = "Git Submodules" })
    return
  end

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

