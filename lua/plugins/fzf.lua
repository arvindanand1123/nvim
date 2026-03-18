return {
  {
    'ibhagwan/fzf-lua',
    event = 'VimEnter',
    config = function()
      local fzf = require 'fzf-lua'

      fzf.setup {
        'telescope',
        buffers = {
          sort_mru = true,
          sort_lastused = true,
        },
        lsp = {
          async_or_timeout = true,
          symbols = {
            async_or_timeout = true,
          },
        },
        winopts = {
          width = 0.95,
          height = 0.9,
          preview = {
            layout = 'vertical',
            vertical = 'up:60%',
          },
        },
      }

      fzf.register_ui_select()

      vim.keymap.set('n', '<leader>sh', fzf.helptags, { desc = 'Search help' })
      vim.keymap.set('n', '<leader>sk', fzf.keymaps, { desc = 'Search keymaps' })
      vim.keymap.set('n', '<leader>sf', fzf.files, { desc = 'Search files' })
      vim.keymap.set('n', '<leader>ss', fzf.builtin, { desc = 'Search select picker' })
      vim.keymap.set('n', '<leader>sg', fzf.live_grep, { desc = 'Search by grep' })
      vim.keymap.set('n', '<leader>sd', fzf.diagnostics_workspace, { desc = 'Search diagnostics' })
      vim.keymap.set('n', '<leader>sr', fzf.resume, { desc = 'Search resume' })
      vim.keymap.set('n', '<leader><leader>', function()
        fzf.buffers {
          sort_mru = true,
          sort_lastused = true,
        }
      end, { desc = 'Find existing buffers' })

      vim.keymap.set('n', '<leader>/', function()
        fzf.blines {
          winopts = {
            preview = {
              hidden = true,
            },
          },
        }
      end, { desc = 'Fuzzily search in current buffer' })

      vim.keymap.set('n', '<leader>s/', function()
        fzf.lines {
          winopts = {
            preview = {
              hidden = true,
            },
          },
        }
      end, { desc = 'Search in open files' })

      vim.keymap.set('n', '<leader>sn', function()
        fzf.files { cwd = vim.fn.stdpath 'config' }
      end, { desc = 'Search neovim files' })

      vim.keymap.set('v', '<leader>sg', fzf.grep_visual, { desc = 'Search by grep with visual selection' })
    end,
  },
}
