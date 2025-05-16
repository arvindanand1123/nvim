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
        desc = 'Format buffer',
      },
    },
    config = function(_, opts)
      local conform = require 'conform'
      local tool_deps = require 'tool-dependencies'

      -- Map tool names to formatter names that use the same binary
      local tool_to_formatters = {
        ruff = { 'ruff_fix', 'ruff_format' },
        eslint_d = { 'eslint_d' },
        stylua = { 'stylua' },
      }

      -- Configure formatters with custom paths if available
      for tool_name, formatter_names in pairs(tool_to_formatters) do
        local custom_path = tool_deps.get_binary_path(tool_name)
        if custom_path then
          for _, formatter_name in ipairs(formatter_names) do
            if conform.formatters[formatter_name] then
              conform.formatters[formatter_name].command = custom_path
            end
          end
        end
      end

      conform.setup(opts)
    end,
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
        local formatters = {
          lua = { 'stylua' },
          python = { 'ruff_fix', 'ruff_format' },
          typescriptreact = { 'eslint_d' },
          typescript = { 'eslint_d' },
        }
        return formatters
      end)(),
    },
  },
}
