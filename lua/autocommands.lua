-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Autosave file on leave
vim.api.nvim_create_autocmd('BufLeave', {
  desc = 'Autosave file on leave',
  group = vim.api.nvim_create_augroup('autosave', { clear = true }),
  callback = function()
    vim.cmd 'silent! update'
  end,
})
