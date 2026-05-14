return {
  {
    'lewis6991/gitsigns.nvim',
    init = function()
      vim.api.nvim_create_user_command('GitQuickfixStatus', function()
        require('git-main-diff').quickfix_status()
      end, {
        desc = 'populate quickfix with git modified and untracked files',
      })

      vim.api.nvim_create_user_command('GitQuickfixDiff', function()
        require('git-main-diff').quickfix_worktree()
      end, {
        desc = 'git diff quickfix files against staged changes',
      })

      local function diff_quickfix_against_base(opts)
        local diff_main = require 'git-main-diff'

        if opts.args == 'worktree' then
          diff_main.quickfix_worktree()
        else
          diff_main.quickfix_index()
        end
      end

      vim.api.nvim_create_user_command('DiffBaseQuickfix', diff_quickfix_against_base, {
        nargs = '?',
        complete = function()
          return { 'index', 'worktree' }
        end,
        desc = 'git diff quickfix files against the default branch',
      })

      vim.api.nvim_create_user_command('DiffMainQuickfix', diff_quickfix_against_base, {
        nargs = '?',
        complete = function()
          return { 'index', 'worktree' }
        end,
        desc = 'git diff quickfix files against the default branch',
      })
    end,
    opts = {
      on_attach = function(bufnr)
        local diff_main = require 'git-main-diff'
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        local function git_map(mode, key, command, desc)
          map(mode, '<leader>g' .. key, command, desc)
        end

        git_map('n', 'hb', gitsigns.blame_line, { desc = 'git blame line' })
        git_map('n', 'hw', diff_main.worktree, { desc = 'git diff worktree against staged changes' })
        git_map('n', 'hd', diff_main.index, { desc = 'git diff worktree against default branch' })
        git_map('n', 'hs', diff_main.quickfix_status, { desc = 'git status quickfix' })
        git_map('n', 'hq', diff_main.quickfix_worktree, { desc = 'git diff quickfix files against staged changes' })
        git_map('n', 'tb', gitsigns.toggle_current_line_blame, { desc = 'Toggle git show blame line' })
      end,

      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
}
