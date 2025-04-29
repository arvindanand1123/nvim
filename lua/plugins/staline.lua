return {
  'tamton-aquib/staline.nvim',
  config = function()
    require('staline').setup {
      sections = {
        left = { '  ', 'mode', ' ', 'branch', ' ', 'lsp' },
        mid = { 'file_name' },
        right = { 'line_column' },
      },
      mode_colors = {
        i = '#FC9867',
        n = '#78DCE8',
        c = '#A9DC76',
        v = '#FF6188',
      },
      defaults = {
        true_colors = true,
        full_path = true,
        line_column = ' [%l/%L] :%c  ',
        branch_symbol = ' ',
        bg = '#121212',
      },
    }
  end,
}
