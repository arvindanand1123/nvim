return {
  'Exafunction/codeium.vim',
  event = 'BufEnter',
  config = function()
    vim.g.codeium_no_map_tab = 1
    vim.g.codeium_manual = true
    vim.keymap.set('i', '<C-a>', function()
      return vim.fn['codeium#Accept']()
    end)
  end,
}
