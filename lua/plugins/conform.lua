return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = 'Format buffer',
      },
    },
    opts = function()
      local tool_deps = require 'tool-dependencies'
      local function bin_or(tool, default)
        return tool_deps.get_binary_path(tool) or default
      end

      local ruff_cmd = bin_or('ruff', 'ruff')
      local stylua_cmd = bin_or('stylua', 'stylua')
      local eslintd_cmd = bin_or('eslint_d', 'eslint_d')

      return {
        notify_on_error = false,
        format_on_save = function(bufnr)
          local disable_filetypes = { c = true, cpp = true }
          local lsp_format_opt = disable_filetypes[vim.bo[bufnr].filetype] and 'never' or 'fallback'
          return { timeout_ms = 500, lsp_format = lsp_format_opt }
        end,
        formatters = {
          ruff_fix = { command = ruff_cmd },
          ruff_format = { command = ruff_cmd },
          stylua = { command = stylua_cmd },
          eslint_d = { command = eslintd_cmd },
        },
        formatters_by_ft = {
          lua = { 'stylua' },
          python = { 'ruff_fix', 'ruff_format' },
          typescriptreact = { 'eslint_d' },
          typescript = { 'eslint_d' },
        },
      }
    end,
    config = function(_, opts)
      require('conform').setup(opts)
    end,
  },
}
