# dotfiles

Contains select app configuration settings.

## nvim

I use the `lazy` plugin manager. Plugins can be found in `nvim/lua/plugins`, with some configuration options for these plugins in `nvim/init.lua`. 

My Neovim setup consists of the following, in no particular order:
- [catppuccin](https://github.com/catppuccin/nvim) because purple is my favourite colour
- [lspconfig](https://github.com/neovim/nvim-lspconfig) for LSP configurations
- [telescope](https://github.com/nvim-telescope/telescope.nvim) for fast fuzzy-finding
- [treesitter](https://github.com/nvim-treesitter/nvim-treesitter) for accurate syntax highlighting
- [trouble](https://github.com/folke/trouble.nvim) to display LSP symbols and diagnostics
- [autopairs](https://github.com/windwp/nvim-autopairs) to auto-place end braces
- [lualine](https://github.com/nvim-lualine/lualine.nvim) for a pretty status bar
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) for autocompletion
- [gitsigns](https://github.com/lewis6991/gitsigns.nvim) for a git gutter
- [no-neck-pain](https://github.com/shortcuts/no-neck-pain.nvim) for occasional single-file editing to center the buffer
