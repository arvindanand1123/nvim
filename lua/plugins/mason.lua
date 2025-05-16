local tool_deps = require 'tool-dependencies'

-- Create a servers table just for LSP configurations
local servers = {}

-- Fill in server configurations from tools with LSP capability
for name, tool in pairs(tool_deps.get_tools_by_capability 'lsp') do
  if tool.config and tool.config.lsp then
    servers[name] = vim.deepcopy(tool.config.lsp)
  else
    servers[name] = {}
  end
end

local ensure_installed = tool_deps.get_mason_managed_tools()

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
