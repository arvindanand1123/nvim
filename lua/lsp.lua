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
        },
      },
    },
  },
  denols = {},
  ts_ls = {
    settings = {
      separate_diagnostic_server = true,
      -- include_completions_with_insert_text = false,
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
  },
}

return servers
