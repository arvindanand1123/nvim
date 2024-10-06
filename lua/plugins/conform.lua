return {
  { -- Autoformat
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
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        local lsp_format_opt
        if disable_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = 'never'
        else
          lsp_format_opt = 'fallback'
        end
        return {
          timeout_ms = 500,
          lsp_format = lsp_format_opt,
        }
      end,
      formatters_by_ft = (function()
        local is_deno_project = vim.fn.filereadable 'deno.json' == 1 or vim.fn.filereadable 'deno.jsonc' == 1
        local prettier_config = { 'prettierd', 'prettier', stop_after_first = true }
        if is_deno_project then
          return {
            lua = { 'stylua' },
            javascript = { 'deno' },
            typescript = { 'deno' },
          }
        else
          return {
            lua = { 'stylua' },
            javascript = prettier_config,
            typescript = prettier_config,
          }
        end
      end)(),
    },
  },
}
