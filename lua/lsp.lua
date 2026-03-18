vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    local fzf = function(picker, opts)
      return function()
        require('fzf-lua')[picker](opts or {})
      end
    end

    local lsp_locations = {
      async_or_timeout = true,
    }

    map('gd', fzf('lsp_definitions', lsp_locations), 'Goto definition')
    map('gr', fzf('lsp_references', vim.tbl_extend('force', lsp_locations, {
      includeDeclaration = false,
    })), 'Goto references')
    map('gI', fzf('lsp_implementations', lsp_locations), 'Goto implementation')
    map('<leader>D', fzf('lsp_typedefs', lsp_locations), 'Type definition')
    map('<leader>ds', fzf('lsp_document_symbols', {
      async_or_timeout = true,
    }), 'Document symbols')
    map('<leader>ws', fzf('lsp_live_workspace_symbols', {
      async_or_timeout = true,
    }), 'Workspace symbols')
    map('<leader>rn', vim.lsp.buf.rename, 'Rename')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })
    map('gD', vim.lsp.buf.declaration, 'Goto declaration')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
      local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, 'Toggle inlay hints')
    end
  end,
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

local mason = require '/plugins/mason'
local servers = mason.servers
local tool_deps = require 'tool-dependencies'

for server_name, _ in pairs(servers) do
  local lspconfig_defaults = require('lspconfig.configs.' .. server_name).default_config

  local config = {
    cmd = lspconfig_defaults.cmd,
    filetypes = lspconfig_defaults.filetypes,
    capabilities = capabilities,
  }

  local lsp_settings = tool_deps.get_tool_config(server_name, 'lsp')
  if lsp_settings and next(lsp_settings) then
    if lsp_settings.init_options then
      config.init_options = vim.deepcopy(lsp_settings.init_options)
      lsp_settings.init_options = nil
    end

    if next(lsp_settings) then
      config.settings = {
        [server_name] = lsp_settings,
      }
    end
  end

  local custom_path = tool_deps.get_binary_path(server_name)
  if custom_path and config.cmd then
    config.cmd[1] = custom_path
  end

  vim.lsp.config(server_name, config)
  vim.lsp.enable(server_name)
end
