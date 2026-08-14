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
}
