return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      local is_deno_project = vim.fn.filereadable 'deno.json' == 1 or vim.fn.filereadable 'deno.jsonc' == 1

      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
        javascript = is_deno_project and { 'deno' } or { 'eslint' },
        typescript = is_deno_project and { 'deno' } or { 'eslint' },
        python = { 'ruff' },
      }

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
