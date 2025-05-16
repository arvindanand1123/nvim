-- Tool dependencies configuration
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
-- Path resolution:
-- - If path is specified and exists: Use that exact binary
-- - If path doesn't exist or is not specified: Use Mason-managed version
--
-- Examples:
-- path = "/Users/username/.local/bin/ruff" -- use local installation
-- path = "ruff" -- use from PATH if available
-- path = nil or not set -- use Mason-managed version

M.tools = {
  pyright = {
    config = {
      lsp = {
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
    },
  },
  ruff = {
    path = '/Users/arvind/.virtualenvs/cinderblock/bin/ruff',
    config = {
      lint = {},
      format = {},
    },
  },
  eslint_d = {
    config = {
      lint = {},
      format = {},
    },
  },
  ts_ls = {
    config = {
      lsp = {},
    },
  },
  stylua = {
    config = {
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
  marksman = {
    config = {
      lsp = {},
    },
  },
}

-- Check if a file exists and is executable
local function is_executable(path)
  if not path then
    return false
  end

  if path:find '/' then
    local exists = vim.fn.filereadable(path) == 1
    local is_exec = vim.fn.executable(path) == 1
    return exists and is_exec
  else
    return vim.fn.executable(path) == 1
  end
end

---Get the effective binary path for a tool
---@param tool_name string The name of the tool
---@return string|nil The binary path if available and valid, nil to use Mason
function M.get_binary_path(tool_name)
  local tool = M.tools[tool_name]
  if not tool then
    return nil
  end

  if tool.path and is_executable(tool.path) then
    return tool.path
  end

  return nil
end

---Get list of tools that should be managed by Mason
---Includes tools without a path or with an invalid path
---@return table List of tool names
function M.get_mason_managed_tools()
  local mason_tools = {}
  for name, tool in pairs(M.tools) do
    if not tool.path or not is_executable(tool.path) then
      table.insert(mason_tools, name)
    end
  end
  return mason_tools
end

---Get tool configuration for a specific system
---@param tool_name string The name of the tool
---@param system string The system type ('lsp', 'lint', 'format')
---@return table Configuration for the specified system
function M.get_tool_config(tool_name, system)
  local tool = M.tools[tool_name]
  if not tool then
    return {}
  end

  local config = {}
  if tool.config and tool.config[system] then
    config = vim.deepcopy(tool.config[system])
  end

  return config
end

---Get all tools that provide a specific capability
---@param capability string The capability to check ('lsp', 'lint', 'format')
---@return table Table of tools with the specified capability
function M.get_tools_by_capability(capability)
  local result = {}
  for name, tool in pairs(M.tools) do
    if tool.config and tool.config[capability] then
      result[name] = tool
    end
  end
  return result
end

return M
