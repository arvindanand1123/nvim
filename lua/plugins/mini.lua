default_n_lines = 500
return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = default_n_lines }
      require('mini.surround').setup { n_lines = default_n_lines }
    end,
  },
}
