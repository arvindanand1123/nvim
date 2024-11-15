local servers = {
  basedpyright = {
    settings = {
      basedpyright = {
        -- Use Ruff instead
        disableOrganizeImports = true,
        analysis = {
          typeCheckingMode = 'off',
        },
      },
    },
  },
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
