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
      return {
        notify_on_error = false,
        format_on_save = function(bufnr)
          local disable_filetypes = { c = true, cpp = true }
          local lsp_format_opt = disable_filetypes[vim.bo[bufnr].filetype] and 'never' or 'fallback'
          return { timeout_ms = 500, lsp_format = lsp_format_opt }
        end,
        formatters = tool_deps.get_formatters_to_command(),
        formatters_by_ft = tool_deps.get_lang_to_formatters(),
      }
    end,
    config = function(_, opts)
      require('conform').setup(opts)
    end,
  },
}
