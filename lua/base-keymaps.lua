-- Quick vertical split with leader v
vim.keymap.set('n', '<leader>v', ':vsplit<CR>', { desc = 'Create vertical split' })

-- Easy way to close current split
vim.keymap.set('n', '<leader>x', ':close<CR>', { desc = 'Close current split' })

-- Make current split full screen
vim.keymap.set('n', '<leader>z', ':only<CR>', { desc = 'Zoom split (make full screen)' })

-- Balance all splits
vim.keymap.set('n', '<leader>=', '<C-w>=', { desc = 'Make splits equal size' })

-- Clear search highlights with <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic quickfix list' })

-- Copy current file path to clipboard
vim.keymap.set('n', '<leader>cp', function()
  local filepath = vim.fn.expand '%:p'
  vim.fn.setreg('+', filepath)
  print('Copied file path: ' .. filepath)
end, { desc = 'Copy current file [P]ath' })

-- Map <Esc><Esc> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Uncomment to disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Remap Ctrl+hjkl for window navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move focus to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move focus to lower window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move focus to upper window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move focus to right window' })

vim.keymap.set('n', 'j', 'gj', { desc = 'Move focus to right window' })
vim.keymap.set('n', 'k', 'gk', { desc = 'Move focus to right window' })
