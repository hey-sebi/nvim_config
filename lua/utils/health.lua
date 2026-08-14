local M = {}

function M.check()
  vim.health.start("Markdown & PDF Export Dependencies")

  -- 1. Pandoc
  if vim.fn.executable("pandoc") == 1 then
    local handle = io.popen("pandoc --version")
    local ver = handle and handle:read("*l") or "installed"
    if handle then
      handle:close()
    end
    vim.health.ok("pandoc: " .. ver)
  else
    vim.health.error("pandoc is not installed or not found in PATH", {
      "Install via Scoop: scoop install pandoc",
      "Install via Winget: winget install JohnMacFarlane.Pandoc",
    })
  end

  -- 2. Typst
  if vim.fn.executable("typst") == 1 then
    local handle = io.popen("typst --version")
    local ver = handle and handle:read("*l") or "installed"
    if handle then
      handle:close()
    end
    vim.health.ok("typst: " .. ver)
  else
    vim.health.error("typst is not installed or not found in PATH", {
      "Install via Scoop: scoop install typst",
      "Install via Winget: winget install typst",
    })
  end

  -- 3. LaTeX converter (latex2text / pylatexenc)
  local has_latex2text = vim.fn.executable("latex2text") == 1
    or (vim.fn.has("win32") == 1 and vim.fn.executable("latex2text.exe") == 1)
  if has_latex2text then
    vim.health.ok("latex2text (pylatexenc): available for in-buffer LaTeX rendering")
  else
    vim.health.warn("latex2text is not installed or not found in PATH", {
      "Install via pip: pip install pylatexenc",
    })
  end

  -- 4. Mermaid filter
  local has_mmd = (vim.fn.has("win32") == 1 and vim.fn.executable("mermaid-filter.cmd") == 1)
    or vim.fn.executable("mermaid-filter") == 1
  if has_mmd then
    vim.health.ok("mermaid-filter: available for PDF diagram compilation")
  else
    vim.health.warn("mermaid-filter is not installed or not found in PATH", {
      "Install via npm: npm install -g mermaid-filter",
    })
  end

  -- 5. Formatters and Linters
  if vim.fn.executable("prettier") == 1 or vim.fn.executable("prettier.cmd") == 1 then
    vim.health.ok("prettier: available for Markdown formatting")
  else
    vim.health.info("prettier: managed via Mason or npm")
  end

  if vim.fn.executable("markdownlint-cli2") == 1 or vim.fn.executable("markdownlint-cli2.cmd") == 1 then
    vim.health.ok("markdownlint-cli2: available for Markdown linting")
  else
    vim.health.info("markdownlint-cli2: managed via Mason or npm")
  end
end

return M
