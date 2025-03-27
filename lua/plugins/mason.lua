local servers = {
  pyright = {
    settings = {
      pyright = {
        -- Use Ruff instead
        disableOrganizeImports = true,
      },
      python = {
        analysis = {
          typeCheckingMode = 'off',
          ignore = { '*' },
        },
      },
    },
  },
  ruff = {},
  ts_ls = {},
  lua_ls = {
    settings = {
      Lua = {
        completion = {
          callSnippet = 'Replace',
        },
        diagnostics = { disable = { 'missing-fields' } },
      },
    },
  },
  marksman = {},
  eslint_d = {},
  stylua = {},
}
local ensure_installed = vim.tbl_keys(servers or {})
return {
  {
    'williamboman/mason.nvim',
    config = true,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = {
      'williamboman/mason.nvim',
    },
    config = function()
      require('mason').setup()
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    end,
  },
  servers = servers,
}
