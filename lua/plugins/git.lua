return {
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        local function git_map(mode, key, command, desc)
          map(mode, '<leader>g' .. key, command, desc)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Jump to next git change' })

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = 'Jump to previous git change' })

        -- Actions
        -- visual mode
        git_map('v', 'hs', function()
          gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'stage git hunk' })
        git_map('v', 'hr', function()
          gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'reset git hunk' })
        -- normal mode
        git_map('n', 'hs', gitsigns.stage_hunk, { desc = 'git stage hunk' })
        git_map('n', 'hr', gitsigns.reset_hunk, { desc = 'git reset hunk' })
        git_map('n', 'hS', gitsigns.stage_buffer, { desc = 'git stage buffer' })
        git_map('n', 'hu', gitsigns.undo_stage_hunk, { desc = 'git undo stage hunk' })
        git_map('n', 'hR', gitsigns.reset_buffer, { desc = 'git reset buffer' })
        git_map('n', 'hp', gitsigns.preview_hunk, { desc = 'git preview hunk' })
        git_map('n', 'hb', gitsigns.blame_line, { desc = 'git blame line' })
        git_map('n', 'hd', gitsigns.diffthis, { desc = 'git diff against index' })
        git_map('n', 'hD', function()
          gitsigns.diffthis '@'
        end, { desc = 'git diff against last commit' })
        -- Toggles
        git_map('n', 'tb', gitsigns.toggle_current_line_blame, { desc = 'Toggle git show blame line' })
        git_map('n', 'tD', gitsigns.toggle_deleted, { desc = 'Toggle git show deleted' })
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
