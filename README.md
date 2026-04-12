# Neovim Configuration (LazyVim based)

This configuration is based on [LazyVim](https://github.com/LazyVim/LazyVim) and
is tailored for a professional development workflow across multiple languages,
with a particular focus on seamless **VSCode integration** and manual control
over code editing.

## Key Features & Customizations

### Language Support

Comprehensive IDE-like features (LSP, Linting, Formatting, Debugging) for:

- **C/C++:** Powered by `clangd` and `cmake-tools.nvim`.
- **Python:** Optimized with `basedpyright` and `ruff`. Includes
  `venv-selector.nvim` for easy virtual environment switching.
- **Web Development:** Full support for TypeScript, JavaScript, HTML, and CSS.
- **Data & Config:** Specialized handling for SQL (`vim-dadbod`), JSON, TOML,
  YAML, and Docker.
- **Markdown:** Custom reflowing and wrapping (100 columns) via Prettier and
  native `textwidth` settings.

### Enhanced Completion via blink.cmp

- **Super-Tab Workflow:** A refined `Tab` behavior that prioritizes accepting
  completion menu suggestions and jumping through snippet placeholders (powered
  by `luasnip`).
- **Clean UI:** Rounded borders for completion and documentation menus for a
  modern look.
- **SQL Integration:** Integrated `vim-dadbod-completion` as a native source for
  `blink.cmp`.

### Deep VSCode Integration

Specifically designed to run headlessly as the backend for the **VSCode Neovim**
extension:

- **Action Delegation:** Native VSCode actions are mapped to standard Neovim
  keybindings (e.g., `<leader>gg` for Git, `<leader>ff` for Quick Open,
  `<leader>ca` for Code Actions).
- **UI Optimization:** Automatically disables UI-heavy plugins (like
  `noice.nvim` and `snacks.nvim` animations) when running in VSCode to prevent
  visual artifacts and ghost text.
- **Split & Tab Management:** Syncs Neovim's window management with VSCode's
  editor groups.

### Quality of Life & Utilities

- **Manual Control:** `mini.pairs` is disabled to allow for predictable, manual
  character pairing.
- **View Centering:** Automatically centers the viewport after searching
  (`n`/`N`) or large vertical jumps (`C-d`/`C-u`).
- **File Utilities:**
  - Copy absolute or relative buffer paths with `<leader>fpa` and `<leader>fpr`.
  - Smart "basename" file picking (ignoring file endings) via custom
    `snacks.picker` logic.
- **Text Manipulation:**
  - Toggle between Doxygen block and line comments with `<leader>ctd`.
  - Trim trailing whitespace with `<leader>ctw`.
- **Yank History:** Integrated `yanky.nvim` for navigating and searching your
  yank ring history.

## Structure

- `lua/config/`: Core options, keymaps, and autocommands.
- `lua/plugins/`: Modular plugin configurations and LazyVim extras.
- `lua/utils/`: Custom Lua helper functions for complex logic.
- `lua/config/vscode-keymaps.lua`: VSCode-specific keybindings, loaded only when
  in a VSCode environment.
