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
        local formatters = {
          lua = { 'stylua' },
          python = { 'ruff_fix', 'ruff_format' },
          javascript = is_deno_project and { 'deno' } or { 'prettierd', 'prettier', stop_after_first = true },
          typescript = is_deno_project and { 'deno' } or { 'prettierd', 'prettier', stop_after_first = true },
        }
        return formatters
      end)(),
    },
  },
}
