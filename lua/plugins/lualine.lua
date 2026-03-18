return {
  'nvim-lualine/lualine.nvim',
  config = function()
    local custom_theme = {
      normal = {
        a = { fg = '#000000', bg = '#78DCE8', gui = 'bold' },
        b = { fg = '#c0c0c0', bg = '#111111' },
        c = { fg = '#8a8a8a', bg = '#0a0a0a' },
      },
      insert = {
        a = { fg = '#000000', bg = '#FC9867', gui = 'bold' },
      },
      visual = {
        a = { fg = '#000000', bg = '#FF6188', gui = 'bold' },
      },
      replace = {
        a = { fg = '#000000', bg = '#AB9DF2', gui = 'bold' },
      },
      command = {
        a = { fg = '#000000', bg = '#A9DC76', gui = 'bold' },
      },
      inactive = {
        a = { fg = '#5c5c5c', bg = '#050505' },
        b = { fg = '#5c5c5c', bg = '#050505' },
        c = { fg = '#5c5c5c', bg = '#050505' },
      },
    }

    require('lualine').setup {
      options = {
        theme = custom_theme,
        globalstatus = true,
        disabled_filetypes = {
          statusline = { 'dashboard', 'alpha', 'starter' },
        },
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        always_divide_middle = false,
        refresh = {
          statusline = 100,
          tabline = 100,
          winbar = 100,
        },
      },

      sections = {
        lualine_a = {
          {
            'mode',
            fmt = function(str)
              return str:sub(1, 1)
            end,
            padding = { left = 1, right = 1 },
          },
        },
        lualine_b = {
          {
            'filename',
            path = 0,
            symbols = {
              modified = ' ●',
              readonly = ' ',
              unnamed = '[No Name]',
              newfile = '[New]',
            },
            padding = { left = 1, right = 1 },
          },
        },
        lualine_c = {},
        lualine_x = {
          {
            'branch',
            icon = '',
            color = { fg = '#78DCE8', bg = '#0a0a0a' },
            padding = { left = 1, right = 1 },
          },
        },
        lualine_y = {
          {
            'diagnostics',
            sources = { 'nvim_diagnostic' },
            sections = { 'error', 'warn', 'info', 'hint' },
            symbols = { error = 'E:', warn = 'W:', info = 'I:', hint = 'H:' },
            colored = true,
            update_in_insert = false,
            always_visible = false,
            padding = { left = 1, right = 1 },
          },
        },
        lualine_z = {
          {
            'location',
            padding = { left = 1, right = 1 },
          },
        },
      },

      inactive_sections = {
        lualine_a = {},
        lualine_b = {
          {
            'filename',
            path = 0,
            padding = { left = 1, right = 1 },
          },
        },
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {
          {
            'location',
            padding = { left = 1, right = 1 },
          },
        },
      },

      extensions = {},
    }
  end,
}
