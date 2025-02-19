return {
  'Exafunction/codeium.vim',
  event = 'BufEnter',
  config = function()
    vim.g.codeium_no_map_tab = 1
    vim.keymap.set('i', '<C-a>', function()
      return vim.fn['codeium#Accept']()
    end, { expr = true, silent = true })
  end,
}
