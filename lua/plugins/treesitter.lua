return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = function()
      require('nvim-treesitter').update()
    end,
    config = function()
      require('nvim-treesitter').setup {}

      local tool_deps = require 'tool-dependencies'

      local defaults = { 'vim', 'vimdoc', 'query', 'markdown_inline' }
      vim.list_extend(defaults, tool_deps.get_langs { use_pure = false })

      require('nvim-treesitter').install(defaults)

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
}
