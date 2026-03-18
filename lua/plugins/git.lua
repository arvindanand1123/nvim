return {
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      on_attach = function(bufnr)
        local diff_main = require 'git_main_diff'
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
        git_map('n', 'hd', diff_main.worktree, { desc = 'git diff worktree against main' })
        git_map('n', 'hD', diff_main.index, { desc = 'git diff staged changes against main' })
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
