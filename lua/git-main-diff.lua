local M = {}

local function run_git(repo, args)
  local command = vim.list_extend({ 'git', '-C', repo }, args)

  if vim.system then
    local result = vim.system(command, { text = true }):wait()
    return result.code == 0, result.stdout or '', result.stderr or ''
  end

  local output = vim.fn.system(command)
  return vim.v.shell_error == 0, output or '', ''
end

local function split_lines(text)
  if text == '' then
    return {}
  end

  text = text:gsub('\n$', '')
  return vim.split(text, '\n', { plain = true, trimempty = false })
end

local function buffer_context(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then
    return nil, 'Current buffer is not backed by a file.'
  end

  path = vim.fs.normalize(path)

  local ok, stdout = run_git(vim.fn.fnamemodify(path, ':h'), { 'rev-parse', '--show-toplevel' })
  if not ok then
    return nil, 'Current buffer is not inside a Git repository.'
  end

  local repo = vim.trim(stdout)
  local prefix = repo .. '/'
  if path:sub(1, #prefix) ~= prefix then
    return nil, 'Current buffer is outside the repository root.'
  end

  return {
    bufnr = bufnr,
    filetype = vim.bo[bufnr].filetype,
    repo = repo,
    relpath = path:sub(#prefix + 1),
  }
end

local function resolve_main_ref(repo)
  for _, ref in ipairs({ 'origin/main', 'main' }) do
    local ok = run_git(repo, { 'rev-parse', '--verify', '--quiet', ref .. '^{commit}' })
    if ok then
      return ref
    end
  end
end

local function read_object(repo, object)
  local exists = run_git(repo, { 'cat-file', '-e', object })
  if not exists then
    return {}
  end

  local ok, stdout, stderr = run_git(repo, { 'show', object })
  if not ok then
    error(vim.trim(stderr) ~= '' and vim.trim(stderr) or ('Failed to read ' .. object))
  end

  return split_lines(stdout)
end

local function scratch_buffer(name, lines, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].filetype = filetype

  return buf
end

local function open_diff_tab(left_buf, right_buf)
  vim.cmd 'tabnew'

  local left_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(left_win, left_buf)

  vim.cmd 'rightbelow vsplit'
  local right_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(right_win, right_buf)

  vim.api.nvim_set_current_win(left_win)
  vim.cmd 'diffthis'

  vim.api.nvim_set_current_win(right_win)
  vim.cmd 'diffthis'
end

local function open_main_diff(kind)
  local context, err = buffer_context(0)
  if not context then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local main_ref = resolve_main_ref(context.repo)
  if not main_ref then
    vim.notify('Could not resolve origin/main or main for this repository.', vim.log.levels.ERROR)
    return
  end

  local ok, message = pcall(function()
    local main_lines = read_object(context.repo, main_ref .. ':' .. context.relpath)
    local right_lines
    local right_name

    if kind == 'index' then
      right_lines = read_object(context.repo, ':' .. context.relpath)
      right_name = 'index://' .. context.relpath
    else
      right_lines = vim.api.nvim_buf_get_lines(context.bufnr, 0, -1, false)
      right_name = 'worktree://' .. context.relpath
    end

    local left = scratch_buffer(main_ref .. '://' .. context.relpath, main_lines, context.filetype)
    local right = scratch_buffer(right_name, right_lines, context.filetype)
    open_diff_tab(left, right)
  end)

  if not ok then
    vim.notify(message, vim.log.levels.ERROR)
  end
end

function M.worktree()
  open_main_diff 'worktree'
end

function M.index()
  open_main_diff 'index'
end

return M
