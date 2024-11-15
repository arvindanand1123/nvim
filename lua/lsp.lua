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
}

return servers
