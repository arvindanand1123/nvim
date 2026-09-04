-- :ToolInfo — debug view of every tool in tool-dependencies.lua, in the spirit of
-- :ConformInfo. Shows how each tool is sourced (mason / fixed / dynamic path), what
-- binary it resolved to, whether its load condition passed for the current cwd, and
-- what conform / nvim-lint / vim.lsp actually ended up with.

local M = {}

local tool_deps = require 'tool-dependencies'

local function source_of(tool)
  if tool.path == nil then
    return 'mason'
  elseif type(tool.path) == 'function' then
    return 'dynamic'
  else
    return 'fixed'
  end
end

local function try(fn, ...)
  local ok, res = pcall(fn, ...)
  if ok then
    return res
  end
  return nil, res
end

-- Render a cmd for display. `call` controls whether function cmds are invoked:
-- nvim-lint cmd functions are pure path lookups, but vim.lsp cmd functions spawn
-- the server, so those are never called here.
local function cmd_to_string(cmd, call)
  if type(cmd) == 'function' then
    if not call then
      return '<function>'
    end
    local ok, res = pcall(cmd)
    cmd = ok and res or ('<error: ' .. tostring(res) .. '>')
  end
  if type(cmd) == 'table' then
    return table.concat(cmd, ' ')
  end
  return tostring(cmd)
end

-- Describe a capability's exclusion, if one is declared. Returns the evaluated
-- result (nil when no exclusion) and a suffix for the status line.
local function exclusion_info(cap_config)
  if cap_config.exclusion == nil then
    return nil, ''
  end
  local ok, res = pcall(cap_config.exclusion)
  if not ok then
    return nil, '  {exclusion() errored: ' .. tostring(res) .. '}'
  end
  return res and true or false, string.format('  {exclusion() -> %s}', tostring(res and true or false))
end

-- Best-effort executable name for a Mason-managed tool: the LSP cmd[1] when known,
-- otherwise the tool name itself (formatters/linters are invoked by bare name).
local function mason_binary(name, tool)
  if tool.config.lsp then
    local cfg = vim.lsp.config[name]
    local cmd = cfg and cfg.cmd
    if type(cmd) == 'table' then
      return cmd[1]
    elseif type(cmd) == 'function' then
      return nil
    end
  end
  return name
end

local function mason_status(name)
  local pkg = name
  local mappings = try(function()
    return require('mason-lspconfig').get_mappings().lspconfig_to_package
  end)
  if mappings and mappings[name] then
    pkg = mappings[name]
  end
  local installed = try(function()
    return require('mason-registry').is_installed(pkg)
  end)
  if installed == nil then
    return pkg, 'unknown (mason not loaded)'
  end
  return pkg, installed and 'installed' or 'NOT installed'
end

local function format_lines(name, tool, bufnr, loaded)
  local lines = {}
  local commands = tool.config.format.commands or { name }
  local excluded, _ = exclusion_info(tool.config.format)
  for _, command in ipairs(commands) do
    local status = 'not loaded'
    if loaded then
      if excluded then
        status = 'excluded'
      else
        local info, err = try(function()
          return require('conform').get_formatter_info(command, bufnr)
        end)
        if info then
          status = string.format(
            'active   conform -> %s  [%s]',
            info.command or '?',
            info.available and 'available' or ('unavailable: ' .. tostring(info.available_msg))
          )
        else
          status = 'active   conform -> <not loaded: ' .. tostring(err) .. '>'
        end
      end
    end
    table.insert(lines, string.format('  format  %-14s %s', command, status))
  end
  return lines
end

local function lint_lines(name, tool, loaded)
  local lines = {}
  local commands = tool.config.lint.commands or { name }
  local excluded, exclusion_suffix = exclusion_info(tool.config.lint)
  for _, command in ipairs(commands) do
    local status = 'not loaded'
    if loaded then
      if excluded then
        status = 'excluded'
      else
        local linter, err = try(function()
          return require('lint').linters[command]
        end)
        if linter then
          status = 'active   nvim-lint -> ' .. cmd_to_string(linter.cmd, true)
        else
          status = 'active   nvim-lint -> <unknown linter: ' .. tostring(err) .. '>'
        end
      end
    end
    table.insert(lines, string.format('  lint    %-14s %s%s', command, status, exclusion_suffix))
  end
  return lines
end

local function lsp_lines(name, tool, bufnr, loaded)
  local status = 'not loaded'
  local excluded, exclusion_suffix = exclusion_info(tool.config.lsp)
  if loaded then
    if excluded then
      status = 'excluded'
    else
      local cfg = vim.lsp.config[name]
      local cmd = cfg and cfg.cmd and cmd_to_string(cfg.cmd, false) or '<no vim.lsp.config>'
      local clients = vim.lsp.get_clients { name = name }
      local attached = vim.lsp.get_clients { name = name, bufnr = bufnr }
      status = string.format('active   cmd -> %s  [clients: %d, attached to buffer: %s]', cmd, #clients, #attached > 0 and 'yes' or 'no')
    end
  end
  return { string.format('  lsp     %-14s %s%s', name, status, exclusion_suffix) }
end

function M.collect(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local out = {}
  local function add(line)
    table.insert(out, line)
  end

  add 'ToolInfo'
  add(string.rep('=', 78))
  add('cwd      : ' .. vim.fn.getcwd())
  add('buffer   : ' .. (vim.api.nvim_buf_get_name(bufnr) ~= '' and vim.api.nvim_buf_get_name(bufnr) or '[No Name]'))
  add('filetype : ' .. (vim.bo[bufnr].filetype ~= '' and vim.bo[bufnr].filetype or '<none>'))
  add('mason bin: ' .. vim.fn.stdpath 'data' .. '/mason/bin')
  add ''

  local names = vim.tbl_keys(tool_deps.tools)
  table.sort(names)

  for _, name in ipairs(names) do
    local tool = tool_deps.tools[name]
    local source = source_of(tool)
    local condition = tool_deps.load_conditions[name]
    local loaded = tool_deps.get_tool(name) ~= nil

    local header = string.format('%-16s [%s]  %s', name, source, loaded and 'loaded' or 'NOT loaded (load condition false for cwd)')
    add(header)
    add(string.rep('-', 78))

    if source == 'mason' then
      local pkg, status = mason_status(name)
      add(string.format('  source  mason package %s: %s', pkg, status))
      local bin = mason_binary(name, tool)
      if bin then
        local exe = vim.fn.exepath(bin)
        add(string.format('  binary  %s', exe ~= '' and exe or ('NOT FOUND on PATH: ' .. bin)))
      else
        add '  binary  <resolved at spawn by cmd function>'
      end
    else
      local resolved, declared = tool_deps.resolve_path(name)
      local declared_label = source == 'dynamic' and 'path()  ->' or 'path      '
      add(string.format('  %s %s', declared_label, declared and tostring(declared) or '<nil>'))
      if resolved then
        add(string.format('  binary  %s', resolved))
      else
        local exe = vim.fn.exepath(name)
        add(string.format('  binary  NOT FOUND -> falls back to bare name %q (%s)', name, exe ~= '' and exe or 'not on PATH'))
      end
    end
    if condition then
      add(string.format('  condition load_conditions.%s() -> %s', name, tostring(loaded)))
    end
    add('  langs   ' .. table.concat(tool.config.langs or {}, ', '))

    if tool.config.lsp then
      vim.list_extend(out, lsp_lines(name, tool, bufnr, loaded))
    end
    if tool.config.lint then
      vim.list_extend(out, lint_lines(name, tool, loaded))
    end
    if tool.config.format then
      vim.list_extend(out, format_lines(name, tool, bufnr, loaded))
    end
    add ''
  end

  return out
end

function M.show()
  local src_buf = vim.api.nvim_get_current_buf()
  local lines = M.collect(src_buf)

  vim.cmd.split()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'toolinfo'
  vim.wo.wrap = false
  vim.wo.spell = false
  pcall(vim.api.nvim_buf_set_name, buf, 'ToolInfo')
  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, nowait = true, desc = 'Close ToolInfo' })
end

vim.api.nvim_create_user_command('ToolInfo', M.show, { desc = 'Show resolved tool-dependencies state (like :ConformInfo, for all tools)' })

return M
