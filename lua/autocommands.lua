-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Autosave file on leave
vim.api.nvim_create_autocmd('BufLeave', {
  desc = 'Autosave file on leave',
  group = vim.api.nvim_create_augroup('autosave', { clear = true }),
  callback = function(event)
    -- `:update` writes any modified buffer, so restrict it to real files.
    -- The quickfix buffer is named `quickfix-N` and quicker.nvim makes it
    -- modifiable, so without this it gets written to disk under that name.
    -- An empty `buftype` means "real file"; every special buffer (quickfix,
    -- oil's acwrite, terminal, help) has a non-empty one. The name check
    -- catches unnamed scratch buffers, which are `buftype = ''` too.
    if vim.bo[event.buf].buftype ~= '' or not vim.bo[event.buf].modifiable then
      return
    end

    if vim.api.nvim_buf_get_name(event.buf) == '' then
      return
    end

    vim.api.nvim_buf_call(event.buf, function()
      vim.cmd 'silent! update'
    end)
  end,
})

-- Uses treesitter indent over default vim indent for python
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  callback = function()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- Open the quickfix/location list automatically after :grep, :make, :vimgrep
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  desc = 'Open quickfix list after a populating command',
  group = vim.api.nvim_create_augroup('auto-open-quickfix', { clear = true }),
  pattern = { '[^l]*' },
  command = 'cwindow',
})

vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  desc = 'Open location list after a populating command',
  group = 'auto-open-quickfix',
  pattern = { 'l*' },
  command = 'lwindow',
})
