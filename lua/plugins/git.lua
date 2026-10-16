-- The remote's default branch (e.g. origin/main), for reviewing a branch
-- against what it will merge into.
local function default_branch()
  local result = vim.system({ 'git', 'rev-parse', '--abbrev-ref', 'origin/HEAD' }, { text = true }):wait()
  if result.code == 0 then
    return vim.trim(result.stdout)
  end
  return 'main'
end

return {
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function git_map(mode, key, command, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, '<leader>g' .. key, command, opts)
        end

        git_map('n', 'hb', gitsigns.blame_line, { desc = 'git blame line' })
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

  { -- VSCode-style review: changed-file explorer beside a side-by-side diff
    'esmuellert/codediff.nvim',
    cmd = 'CodeDiff',
    keys = {
      { '<leader>ghs', '<cmd>CodeDiff<CR>', desc = 'git review working tree changes' },
      { '<leader>ghw', '<cmd>CodeDiff file HEAD<CR>', desc = 'git diff file against HEAD' },
      {
        '<leader>ghd',
        function()
          vim.cmd('CodeDiff file ' .. default_branch() .. '...')
        end,
        desc = 'git diff file against default branch',
      },
      {
        '<leader>ghm',
        function()
          vim.cmd('CodeDiff ' .. default_branch() .. '...')
        end,
        desc = 'git review branch against default branch',
      },
      { '<leader>ghl', '<cmd>CodeDiff history %<CR>', desc = 'git history of file' },
    },
    opts = {
      -- Background-only tints tuned for the #0c0c0c Ghostty background, so
      -- syntax colours stay readable on changed lines.
      highlights = {
        line_insert = '#16261b',
        line_delete = '#2b1619',
        char_insert = '#24452d',
        char_delete = '#4d2329',
      },
      explorer = {
        -- Moving through the file list opens each diff, like stepping
        -- through a quickfix list.
        auto_open_on_cursor = true,
        line_stats = { enabled = true, count_untracked = true },
      },
    },
  },
}
