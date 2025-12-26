local M = {}

-- Structure:
--   toolname = {
--     path = string|nil,      -- Optional. Custom binary path for the tool
--     config = {              -- Configuration organized by capability
--       lsp = {},            -- LSP server configuration
--       lint = {},           -- Linter configuration
--       format = {},         -- Formatter configuration
--     }
--   }
--

M.tools = {
  basedpyright = {
    config = {
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
      lint = {
        commands = { 'ruff' },
      },
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
      lint = {
        commands = { 'eslint_d' },
      },
      format = {
        commands = { 'eslint_d' },
      },
    },
  },
  ts_ls = {
    langs = { 'typescript', 'typescriptreact' },
    config = {
      lsp = {},
    },
  },
  stylua = {
    config = {
      langs = { 'lua' },
      format = {
        commands = { 'stylua' },
      },
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

function M.get_binary_path(tool_name)
  local tool = M.tools[tool_name]
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
  for name, tool in pairs(M.tools) do
    if not tool.path then
      table.insert(mason_tools, name)
    end
  end
  return mason_tools
end

function M.get_tool_config(tool_name, capability)
  local tool = M.tools[tool_name]
  local config = {}
  if tool.config and tool.config[capability] then
    config = vim.deepcopy(tool.config[capability])
  end

  return config
end

function M.get_tools_by_capability(capability)
  local result = {}
  for name, tool in pairs(M.tools) do
    if tool.config and tool.config[capability] then
      result[name] = tool
    end
  end
  return result
end

local function bin_or(tool, default)
  return M.get_binary_path(tool) or default
end

function M.get_formatters_to_command()
  local formatters = M.get_tools_by_capability 'format'
  local formatters_to_command = {}
  for name, tool in pairs(formatters) do
    local commands = tool.config.format.commands
    for _, c in ipairs(commands) do
      formatters_to_command[c] = { command = bin_or(name, name) }
    end
  end
  return formatters_to_command
end

function M.get_lang_to_formatters()
  local formatters = M.get_tools_by_capability 'format'
  local lang_to_formatters = {}
  for _, tool in pairs(formatters) do
    local langs = tool.config.langs
    local commands = tool.config.format.commands
    for _, l in ipairs(langs) do
      lang_to_formatters[l] = commands
    end
  end
  return lang_to_formatters
end

function M.get_lang_to_linters()
  local linters = M.get_tools_by_capability 'lint'
  local lang_to_linters = {}
  for _, tool in pairs(linters) do
    local langs = tool.config.langs
    local commands = tool.config.lint.commands
    for _, l in ipairs(langs) do
      lang_to_linters[l] = commands
    end
  end
  return lang_to_linters
end

return M
