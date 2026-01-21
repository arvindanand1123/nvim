-- lspconfig is used only for its server configuration database
-- Actual LSP setup is done via vim.lsp.config() in lua/lsp.lua
return {
  'neovim/nvim-lspconfig',
  lazy = false,
}
