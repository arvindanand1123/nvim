local M = {}

-- Structure:
--   toolname = {
--     path = string|nil,       -- Optional. Custom binary path for the tool
--     config = {               -- Configuration organized by capability
--       lsp = {},             -- LSP server configuration
--       lint = {},            -- Linter configuration
--       format = {},          -- Formatter configuration
--     }
--   }
--

M.tools = {
  basedpyright = {
    config = {
      langs = { 'python' },
      lsp = {
        disableOrganizeImports = true, -- Disable organize imports feature (use Ruff instead)
        analysis = {
          typeCheckingMode = 'off',
          ignore = { '*' }, -- Ignore all files for diagnostics (use Ruff for linting)
        },
      },
    },
  },
  ruff = {
    path = '~/.virtualenvs/cinderblock/bin/ruff',
    config = {
      langs = { 'python' },
      lint = {},
      format = {
        commands = {
          'ruff_fix',
          'ruff_format',
        },
      },
    },
  },
  eslint_d = {
    path = '~/Library/pnpm/eslint_d',
    config = {
      langs = { 'typescript', 'typescriptreact' },
      lint = {},
      format = {},
    },
  },
  denols = {
    path = '~/.deno/bin/deno',
    config = {
      langs = { 'typescript' },
      lsp = { commands = 'deno_lsp' },
    },
  },
  deno = {
    path = '~/.deno/bin/deno',
    config = {
      langs = { 'typescript' },
      format = {
        commands = { 'deno_fmt' },
      },
    },
  },
  ts_ls = {
    config = {
      langs = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
      lsp = {},
    },
  },
  stylua = {
    config = {
      langs = { 'lua' },
      format = {},
    },
  },
  lua_ls = {
    config = {
      lsp = {
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
  },
  rust_analyzer = {
    config = {
      lsp = {
        cargo = { allFeatures = true },
        checkOnSave = { command = 'clippy' },
        inlayHints = { enable = true },
      },
    },
  },
  marksman = {
    config = {
      lsp = {},
    },
  },
}

-- Define conditions for loading a particular tool
-- Structure:
--   toolname = function()
--
-- Access tool spec:
-- If toolname has been defined,
--  If load_condition then, return tool config
--  Else, return Nil
-- Else,
--  return tool config
--
--
--

local function detect_project_type_ts()
  local fname = vim.fn.getcwd()

  local util = require 'lspconfig.util'
  local deno_root = util.root_pattern('deno.json', 'deno.jsonc')(fname)
  local node_root = util.root_pattern('package.json', 'tsconfig.json', 'jsconfig.json')(fname)

  if deno_root and node_root then
    -- tie-break rule: prefer deno
    return 'deno', deno_root
  elseif deno_root then
    return 'deno', deno_root
  elseif node_root then
    return 'node', node_root
  else
    return 'none', nil
  end
end

M.load_conditions = {
  deno = function()
    return detect_project_type_ts() == 'deno'
  end,
  denols = function()
    return detect_project_type_ts() == 'deno'
  end,
  ts_ls = function()
    return detect_project_type_ts() == 'node'
  end,
  eslint_d = function()
    return detect_project_type_ts() == 'node'
  end,
}

local function is_executable(path)
  if path then
    if path:find '/' then
      local exists = vim.fn.filereadable(path) == 1
      local is_exec = vim.fn.executable(path) == 1
      return exists and is_exec
    else
      return vim.fn.executable(path) == 1
    end
  else
    return false
  end
end

function M.get_tool(tool_name)
  local tool = M.tools[tool_name]
  if not tool then
    return nil
  else
    local condition = M.load_conditions[tool_name]
    if condition then
      if condition() then
        return tool
      else
        return nil
      end
    else
      return tool
    end
  end
end

function M.get_binary_path(tool_name)
  local tool = M.get_tool(tool_name)
  if tool then
    local path = tool.path and vim.fn.expand(tool.path) or nil
    if path and is_executable(path) then
      return path
    end
  else
    return nil
  end
end

function M.get_mason_managed_tools()
  local mason_tools = {}
  local lspconfig_to_package = require('mason-lspconfig').get_mappings().lspconfig_to_package
  for name, _ in pairs(M.tools) do
    local tool = M.get_tool(name)
    if tool then
      if not tool.path then
        local mason_name = lspconfig_to_package[name] or name
        table.insert(mason_tools, mason_name)
      end
    end
  end
  return mason_tools
end

function M.get_tool_config(tool_name, capability)
  local tool = M.get_tool(tool_name)
  local config = {}
  if tool then
    if tool.config and tool.config[capability] then
      config = vim.deepcopy(tool.config[capability])
    end
    if capability == 'lsp' then
      local bin_name
      local bin_path = M.get_binary_path(tool_name)
      if bin_path then
        bin_name = bin_path
      else
        bin_name = tool_name
      end
      config.cmd = { bin_name, 'lsp' }
    end
  end
  return config
end

function M.get_tools_by_capability(capability)
  local result = {}
  for name, _ in pairs(M.tools) do
    local tool = M.get_tool(name)
    if tool then
      if tool.config and tool.config[capability] then
        result[name] = tool
      end
    end
  end
  return result
end

function M.get_formatters_to_command()
  local formatters = M.get_tools_by_capability 'format'
  local formatters_to_command = {}
  for name, tool in pairs(formatters) do
    local commands = tool.config.format.commands or { name }
    for _, command in ipairs(commands) do
      formatters_to_command[command] = { command = M.get_binary_path(name) or name }
    end
  end
  return formatters_to_command
end

function M.get_lang_to_formatters()
  local formatters = M.get_tools_by_capability 'format'
  local lang_to_formatters = {}
  for name, tool in pairs(formatters) do
    local langs = tool.config.langs
    local commands = tool.config.format.commands or { name }
    for _, l in ipairs(langs) do
      lang_to_formatters[l] = commands
    end
  end
  return lang_to_formatters
end

function M.get_lang_to_linters()
  local linters = M.get_tools_by_capability 'lint'
  local lang_to_linters = {}
  for name, tool in pairs(linters) do
    local langs = tool.config.langs
    local commands = tool.config.lint.commands or { name }
    for _, l in ipairs(langs) do
      lang_to_linters[l] = commands
    end
  end
  return lang_to_linters
end

return M
