return {
  {
    'polirritmico/monokai-nightasty.nvim',
    priority = 1000,
    init = function()
      vim.cmd 'colorscheme monokai-nightasty'
    end,
    opts = {
      dark_style_background = 'transparent',
    },
  },
}
