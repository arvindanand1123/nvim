local ghostty = {
  background = '#0c0c0c',
  surface = '#1a1a1a',
  selection = '#343434',
}

return {
  {
    'polirritmico/monokai-nightasty.nvim',
    priority = 1000,
    init = function()
      vim.cmd 'colorscheme monokai-nightasty'
    end,
    opts = {
      dark_style_background = ghostty.background,
      on_colors = function(colors)
        colors.bg_float = ghostty.surface
        colors.bg_sidebar = ghostty.surface
        colors.bg_popup = ghostty.surface
        colors.bg_menuselbar = ghostty.surface
        colors.bg_statusline = ghostty.selection
        colors.bg_menusel = ghostty.selection
        colors.border_highlight = colors.grey_dark
      end,
    },
  },
}
