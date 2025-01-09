-- Run `:checkhealth` if you encounter installation errors

-- Set <space> as leader key (before plugins)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if using a Nerd Font
vim.g.have_nerd_font = false

-- Set spelling and lang to en_us
vim.opt.spell = true
vim.opt.spelllang = { 'en_us' }

-- [[ Options ]]
-- See `:help vim.opt` and `:help option-list`

-- Enable line numbers (current line absolute, others relative)
vim.opt.number = true
vim.opt.relativenumber = true

-- Enable mouse mode (e.g., for resizing splits)
vim.opt.mouse = 'a'

-- Hide mode (already in status line)
vim.opt.showmode = false

-- Sync clipboard with OS (after UiEnter to reduce startup time)
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive search unless capitals used
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Faster which-key popup (reduce timeoutlen)
vim.opt.timeoutlen = 300

-- Open splits to right and below
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Show whitespace characters (see :help 'listchars')
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Live substitution preview (inccommand)
vim.opt.inccommand = 'split'

-- Quick vertical split with leader v
vim.keymap.set('n', '<leader>v', ':vsplit<CR>', { desc = 'Create vertical split' })

-- Easy way to close current split
vim.keymap.set('n', '<leader>x', ':close<CR>', { desc = 'Close current split' })

-- Make current split full screen
vim.keymap.set('n', '<leader>z', ':only<CR>', { desc = 'Zoom split (make full screen)' })

-- Balance all splits
vim.keymap.set('n', '<leader>=', '<C-w>=', { desc = 'Make splits equal size' })

-- Highlight current line (cursorline)
vim.opt.cursorline = true

-- Keep 10 lines visible above/below cursor (scrolloff)
vim.opt.scrolloff = 10

-- [[ Keymaps ]]
-- See `:help vim.keymap.set()`

-- Clear search highlights with <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

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

-- [[ Autocommands ]]
-- See `:help lua-guide-autocommands`

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
-- See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install 3rd party plugins via lazy ]]
-- Run :Lazy to check plugin status; :Lazy update to update plugins
require('lazy').setup({
  { import = 'plugins' },
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- [[ Configure custom plugins ]]
-- Set path to .vim or .nvim file/repo by adding it to vim-plugs.lua
local vim_plugs = require 'plugins/custom/vim-plugs'

-- Loop through the plugin paths and source each one
for _, plugin_path in ipairs(vim_plugs) do
  -- Should quietly fail
  pcall(function()
    vim.cmd('source ' .. plugin_path)
  end)
end
