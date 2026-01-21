-- Run `:checkhealth` if you encounter installation errors

-- Set <space> as leader key (before plugins)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if using a Nerd Font
vim.g.have_nerd_font = true

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

-- Disable swap files
vim.opt.swapfile = false

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

-- Highlight current line (cursorline)
vim.opt.cursorline = true

-- Keep 10 lines visible above/below cursor (scrolloff)
vim.opt.scrolloff = 10

-- [[ Basic Editor Keymaps ]]
require 'base-keymaps'

-- [[ Autocommands ]]
require 'autocommands'

-- [[ Install `lazy.nvim` plugin manager ]]
-- See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install 3rd party plugins via lazy ]]
-- Run :Lazy to check plugin status; :Lazy update to update plugins
require('lazy').setup({
  { import = 'plugins' },
}, {
  ui = {
    icons = vim.g.have_nerd_font and {},
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

-- [[ LSP Configuration ]]
require 'lsp'
