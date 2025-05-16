return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      local tool_deps = require 'tool-dependencies'

      lint.linters_by_ft = {
        typescriptreact = { 'eslint_d' },
        typescript = { 'eslint_d' },
        python = { 'ruff' },
      }

      local linters = {}
      for linter, _ in pairs(lint.linters_by_ft) do
        table.insert(linters, linter)
      end

      -- Configure all linters to use custom binary paths if available
      for _, linter_name in ipairs(linters) do
        local custom_path = tool_deps.get_binary_path(linter_name)
        if custom_path and lint.linters[linter_name] then
          lint.linters[linter_name].cmd = custom_path
        end
      end

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
