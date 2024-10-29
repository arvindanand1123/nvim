local servers = {
  -- clangd = {},
  -- gopls = {},
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
  tsserver = {
    settings = {
      separate_diagnostic_server = true,
      tsserver_file_preferences = {
        autoImportFileExcludePatterns = {
          'antd',
          'react-i18next',
          'i18next',
          'module',
          'webpack',
        },
      },
    },
  },
  -- rust_analyzer = {},
  denols = {},
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
}

return servers
