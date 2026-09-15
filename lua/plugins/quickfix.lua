return {
  { -- Modern quickfix: syntax highlighting, context expansion, editable list
    'stevearc/quicker.nvim',
    ft = 'qf',
    keys = {
      {
        '<leader>q',
        function()
          require('quicker').toggle()
        end,
        desc = 'Toggle quickfix list',
      },
      {
        '<leader>Q',
        function()
          require('quicker').toggle { loclist = true }
        end,
        desc = 'Toggle location list',
      },
    },
    opts = {
      -- Buffer/window options applied to the quickfix window.
      -- `spell` is on globally (see init.lua), which squiggles every filename.
      opts = {
        spell = false,
      },
      keys = {
        {
          '>',
          function()
            require('quicker').expand { before = 2, after = 2, add_to_existing = true }
          end,
          desc = 'Expand quickfix context',
        },
        {
          '<',
          function()
            require('quicker').collapse()
          end,
          desc = 'Collapse quickfix context',
        },
      },
      -- Edit the quickfix buffer like any other buffer and `:w` to apply the
      -- changes across every listed file. Deleting a line drops that entry.
      edit = {
        enabled = true,
        autosave = 'unmodified',
      },
      highlight = {
        treesitter = true,
        lsp = true,
      },
    },
  },
}
