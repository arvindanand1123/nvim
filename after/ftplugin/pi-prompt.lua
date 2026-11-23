-- The pi-nvim-bridge ftplugin maps <Tab> in the prompt buffer to pi's
-- completion: accept the open menu, or else force an @file / path / shell
-- lookup. Here <Tab> indents as it does in any other buffer. Completions still
-- pop up while typing; <CR> or <C-Y> accepts one, <C-N>/<C-P> move through them.
-- This runs after the plugin's ftplugin, so the mapping below replaces its own.
vim.keymap.set('i', '<Tab>', '<Tab>', { buffer = 0, desc = 'Indent' })
