return {
  'tamton-aquib/staline.nvim',
  config = function()
    require('staline').setup {
      sections = {
        left = { ' ', 'mode', ' ', 'file_name', ' ', 'lsp' },
        mid = { 'branch' },
        right = { 'line_column' },
      },
      inactive_sections = {
        left = {},
        mid = { 'file_name' },
        right = {},
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
        bg = 'black',
        inactive_color = 'white',
        inactive_bgcolor = 'black',
      },
    }
  end,
}
