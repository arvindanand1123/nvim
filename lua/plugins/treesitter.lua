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

      local defaults = {
        'lua',
        'vim',
        'vimdoc',
        'query',
        'python',
        'javascript',
        'typescript',
        'tsx',
        'rust',
      }

      require('nvim-treesitter').install(defaults)

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
}
