-- REQUIREMENTS:
--  1) LaTeX support
--    for LaTeX support in nvim we need to install `pylatexenc`: pip install pylatexenc
--  2) PDF rendering, install pandoc and typst
--    PDF with markdown support: npm install -g mermaid-filter
--    [Windows] scoop install pandoc typst

local prettier_config_files = {
  ".prettierrc",
  ".prettierrc.json",
  ".prettierrc.yml",
  ".prettierrc.yaml",
  ".prettierrc.json5",
  ".prettierrc.js",
  ".prettierrc.cjs",
  ".prettierrc.mjs",
  ".prettierrc.ts",
  ".prettierrc.cts",
  ".prettierrc.mts",
  ".prettierrc.toml",
  "prettier.config.js",
  "prettier.config.cjs",
  "prettier.config.mjs",
  "prettier.config.ts",
  "prettier.config.cts",
  "prettier.config.mts",
}

local markdownlint_config_files = {
  ".markdownlint.json",
  ".markdownlint.jsonc",
  ".markdownlint.yaml",
  ".markdownlint.yml",
  ".markdownlintrc",
  ".markdownlint-cli2.jsonc",
  ".markdownlint-cli2.yaml",
  ".markdownlint-cli2.cjs",
  ".markdownlint-cli2.mjs",
}

local function has_prettier_config(ctx)
  if not ctx or not ctx.dirname or ctx.dirname == "" then
    return false
  end
  return vim.fs.root(ctx.dirname, prettier_config_files) ~= nil
end

local function has_markdownlint_config(dir)
  if not dir or dir == "" then
    return false
  end
  return vim.fs.root(dir, markdownlint_config_files) ~= nil
end

local function export_markdown_to_pdf()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)

  if file == "" or vim.bo[buf].filetype ~= "markdown" then
    vim.notify("Active buffer is not a saved Markdown file", vim.log.levels.WARN, { title = "Markdown Export" })
    return
  end

  if vim.fn.executable("pandoc") ~= 1 then
    vim.notify("pandoc executable not found in PATH", vim.log.levels.ERROR, { title = "Markdown Export" })
    return
  end

  -- Save if modified
  if vim.bo[buf].modified then
    vim.cmd("silent! write")
  end

  local pdf_file = vim.fn.fnamemodify(file, ":r") .. ".pdf"
  local pdf_name = vim.fn.fnamemodify(pdf_file, ":t")

  vim.notify("Compiling " .. pdf_name .. "...", vim.log.levels.INFO, { title = "Markdown Export" })

  local cmd = { "pandoc", file, "-o", pdf_file, "--pdf-engine=typst" }
  if vim.fn.has("win32") == 1 and vim.fn.executable("mermaid-filter.cmd") == 1 then
    table.insert(cmd, "-F")
    table.insert(cmd, "mermaid-filter.cmd")
  elseif vim.fn.executable("mermaid-filter") == 1 then
    table.insert(cmd, "-F")
    table.insert(cmd, "mermaid-filter")
  end

  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code == 0 then
        vim.notify("Successfully exported: " .. pdf_name, vim.log.levels.INFO, { title = "Markdown Export" })
      else
        local err_msg = (obj.stderr and obj.stderr ~= "") and obj.stderr or ("Exit code " .. tostring(obj.code))
        vim.notify("PDF export failed:\n" .. err_msg, vim.log.levels.ERROR, { title = "Markdown Export" })
      end
    end)
  end)
end

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "prettier" },
      },
      formatters = {
        prettier = {
          prepend_args = function(self, ctx)
            -- If the project/repo has its own Prettier config, don't pass CLI overrides
            -- so that the repo's configuration (e.g. printWidth: 90) takes precedence.
            if has_prettier_config(ctx) then
              return {}
            end
            -- Fallback defaults when no repo-level Prettier config exists
            return { "--prose-wrap", "always", "--print-width", "80" }
          end,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local lint = require("lint")
      local base_linter = lint.linters["markdownlint-cli2"]
      if base_linter then
        lint.linters["markdownlint-cli2"] = function()
          local linter = type(base_linter) == "function" and base_linter() or vim.deepcopy(base_linter)
          local cur_file = vim.api.nvim_buf_get_name(0)
          local cur_dir = cur_file ~= "" and vim.fs.dirname(cur_file) or vim.uv.cwd()
          if has_markdownlint_config(cur_dir) then
            linter.args = { "-" }
          else
            linter.args = {
              "--config",
              vim.fn.stdpath("config") .. "/.markdownlint-cli2.jsonc",
              "--",
              "-",
            }
          end
          return linter
        end
      end
    end,
  },
  {
    "iamcco/markdown-preview.nvim",
    keys = {
      {
        "<leader>cP",
        export_markdown_to_pdf,
        ft = "markdown",
        desc = "Markdown Export PDF (Pandoc + Typst)",
      },
    },
  },
}
