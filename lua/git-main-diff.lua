local M = {}
local uv = vim.uv or vim.loop
local left_diff_winhighlight = table.concat({
  'DiffDelete:Normal',
}, ',')
local right_diff_winhighlight = table.concat({
  'DiffAdd:DiffDelete',
  'DiffDelete:Normal',
}, ',')

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

local function existing_dir(path)
  local stat = uv.fs_stat(path)
  if stat and stat.type == 'directory' then
    return path
  end

  local dir = vim.fs.dirname(path)

  while dir and dir ~= '' do
    local stat = uv.fs_stat(dir)
    if stat and stat.type == 'directory' then
      return dir
    end

    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end

    dir = parent
  end
end

local function repo_root(path)
  path = vim.fs.normalize(path)

  local cwd = existing_dir(path)
  if not cwd then
    return nil, ('Could not find a parent directory for %s.'):format(path)
  end

  local ok, stdout = run_git(cwd, { 'rev-parse', '--show-toplevel' })
  if not ok then
    return nil, ('%s is not inside a Git repository.'):format(path)
  end

  return vim.trim(stdout)
end

local function context_for_path(path, opts)
  opts = opts or {}
  if path == '' then
    return nil, 'No file path was provided.'
  end

  path = vim.fs.normalize(path)

  local repo, err = repo_root(path)
  if not repo then
    return nil, err
  end

  local prefix = repo .. '/'
  if path:sub(1, #prefix) ~= prefix then
    return nil, ('%s is outside the repository root.'):format(path)
  end

  return {
    bufnr = opts.bufnr,
    filetype = opts.filetype or '',
    path = path,
    repo = repo,
    relpath = path:sub(#prefix + 1),
  }
end

local function buffer_context(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then
    return nil, 'Current buffer is not backed by a file.'
  end

  return context_for_path(path, {
    bufnr = bufnr,
    filetype = vim.bo[bufnr].filetype,
  })
end

local function current_repo()
  local candidates = {}
  local seen = {}
  local errors = {}

  local bufpath = vim.api.nvim_buf_get_name(0)
  if bufpath ~= '' then
    table.insert(candidates, bufpath)
  end

  table.insert(candidates, vim.fn.getcwd())

  for _, candidate in ipairs(candidates) do
    candidate = vim.fs.normalize(candidate)
    if not seen[candidate] then
      seen[candidate] = true

      local repo, err = repo_root(candidate)
      if repo then
        return repo
      end

      if err then
        table.insert(errors, err)
      end
    end
  end

  return nil, table.concat(errors, '\n')
end

local function ref_exists(repo, ref)
  return run_git(repo, { 'rev-parse', '--verify', '--quiet', ref .. '^{commit}' })
end

local function remote_names(repo)
  local ok, stdout = run_git(repo, { 'remote' })
  if not ok then
    return {}
  end

  local remotes = {}
  for _, remote in ipairs(split_lines(stdout)) do
    if remote ~= '' then
      table.insert(remotes, remote)
    end
  end

  return remotes
end

local function current_upstream_remote(repo)
  local ok, stdout = run_git(repo, { 'rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}' })
  if not ok then
    return
  end

  return vim.trim(stdout):match '^([^/]+)/'
end

local function remote_default_ref(repo, remote)
  local ok, stdout = run_git(repo, { 'symbolic-ref', '--quiet', ('refs/remotes/%s/HEAD'):format(remote) })
  if not ok then
    return
  end

  local full_ref = vim.trim(stdout)
  return full_ref:gsub('^refs/remotes/', '')
end

local function resolve_base_ref(repo)
  local candidates = {}
  local seen = {}

  local function add(ref)
    if ref and ref ~= '' and not seen[ref] then
      seen[ref] = true
      table.insert(candidates, ref)
    end
  end

  local upstream_remote = current_upstream_remote(repo)
  add(remote_default_ref(repo, upstream_remote))

  for _, remote in ipairs(remote_names(repo)) do
    add(remote_default_ref(repo, remote))
  end

  for _, ref in ipairs { 'origin/main', 'origin/master', 'main', 'master' } do
    add(ref)
  end

  for _, ref in ipairs(candidates) do
    if ref_exists(repo, ref) then
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

local function index_lines(context)
  return read_object(context.repo, ':' .. context.relpath)
end

local function parse_status_entries(text)
  local entries = {}
  local chunks = vim.split(text, '\0', { plain = true, trimempty = true })
  local i = 1

  while i <= #chunks do
    local raw = chunks[i]
    local status = raw:sub(1, 2)
    local path = raw:sub(4)

    table.insert(entries, {
      path = path,
      status = status,
    })

    if status:find '[RC]' then
      i = i + 1
    end

    i = i + 1
  end

  return entries
end

local function status_matches(status)
  local tracked_status = {
    ['??'] = true,
    ['!!'] = false,
    A = true,
    C = true,
    D = true,
    M = true,
    R = true,
    T = true,
    U = true,
  }

  return tracked_status[status] or tracked_status[status:sub(1, 1)] or tracked_status[status:sub(2, 2)] or false
end

local function git_status_quickfix_items(repo)
  local ok, stdout, stderr = run_git(repo, { 'status', '--porcelain=v1', '-z', '--untracked-files=all' })
  if not ok then
    return nil, vim.trim(stderr) ~= '' and vim.trim(stderr) or 'Failed to read git status.'
  end

  local parsed_values = parse_status_entries(stdout)

  local items = {}
  for _, entry in ipairs(parsed_values) do
    if status_matches(entry.status) then
      table.insert(items, {
        col = 1,
        filename = vim.fs.normalize(repo .. '/' .. entry.path),
        lnum = 1,
        text = entry.status .. ' ' .. entry.path,
      })
    end
  end

  return items
end

local function open_file_buffer(win, context)
  if context.bufnr and context.bufnr > 0 and vim.api.nvim_buf_is_loaded(context.bufnr) then
    vim.api.nvim_win_set_buf(win, context.bufnr)
    return
  end

  vim.api.nvim_set_current_win(win)
  vim.cmd('edit ' .. vim.fn.fnameescape(context.path))
end

local function open_diff_tab(context, right_buf)
  vim.cmd 'tabnew'

  local left_win = vim.api.nvim_get_current_win()
  open_file_buffer(left_win, context)

  vim.cmd 'rightbelow vsplit'
  local right_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(right_win, right_buf)

  vim.api.nvim_set_current_win(left_win)
  vim.cmd 'diffthis'
  vim.wo[left_win].winhighlight = left_diff_winhighlight
  vim.wo[left_win].foldenable = false

  vim.api.nvim_set_current_win(right_win)
  vim.cmd 'diffthis'
  vim.wo[right_win].winhighlight = right_diff_winhighlight
  vim.wo[right_win].foldenable = false

  vim.api.nvim_set_current_win(left_win)
end

local function open_context_diff(context, kind)
  return pcall(function()
    if kind == 'worktree' then
      local right = scratch_buffer('index://' .. context.relpath, index_lines(context), context.filetype)
      open_diff_tab(context, right)
      return
    end

    local base_ref = resolve_base_ref(context.repo)
    if not base_ref then
      error 'Could not resolve the default branch for this repository.'
    end

    if kind == 'index' then
      local right = scratch_buffer(base_ref .. '://' .. context.relpath, read_object(context.repo, base_ref .. ':' .. context.relpath), context.filetype)
      open_diff_tab(context, right)
      return
    end

    error(('Unsupported diff kind: %s'):format(kind))
  end)
end

local function open_main_diff(kind)
  local context, err = buffer_context(0)
  if not context then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local ok, message = open_context_diff(context, kind)

  if not ok then
    vim.notify(message, vim.log.levels.ERROR)
  end
end

local function quickfix_contexts()
  local items = vim.fn.getqflist()
  if vim.tbl_isempty(items) then
    return {}, { 'Quickfix list is empty.' }
  end

  local contexts = {}
  local errors = {}
  local seen = {}

  for _, item in ipairs(items) do
    local bufnr = item.bufnr and item.bufnr > 0 and item.bufnr or nil
    local path = ''

    if bufnr then
      path = vim.api.nvim_buf_get_name(bufnr)
    end

    if path == '' and item.filename and item.filename ~= '' then
      path = vim.fn.fnamemodify(item.filename, ':p')
    end

    if path ~= '' then
      path = vim.fs.normalize(path)

      if not seen[path] then
        seen[path] = true

        local filetype = ''
        if bufnr then
          filetype = vim.bo[bufnr].filetype
        end

        if filetype == '' then
          filetype = vim.filetype.match { filename = path } or ''
        end

        local context, err = context_for_path(path, {
          bufnr = bufnr,
          filetype = filetype,
        })

        if context then
          table.insert(contexts, context)
        else
          table.insert(errors, err)
        end
      end
    end
  end

  return contexts, errors
end

local function open_quickfix_diffs(kind)
  local contexts, errors = quickfix_contexts()
  if vim.tbl_isempty(contexts) then
    vim.notify(table.concat(errors, '\n'), vim.log.levels.ERROR)
    return
  end

  local opened = 0
  for _, context in ipairs(contexts) do
    local ok, err = open_context_diff(context, kind)
    if ok then
      opened = opened + 1
    else
      table.insert(errors, err)
    end
  end

  if not vim.tbl_isempty(errors) then
    vim.notify(table.concat(errors, '\n'), vim.log.levels.WARN)
  end

  if opened > 0 then
    vim.notify(('Opened %d diff tab%s from quickfix.'):format(opened, opened == 1 and '' or 's'))
  end
end

local function populate_quickfix_from_status()
  local repo, err = current_repo()
  if not repo then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local items, status_err = git_status_quickfix_items(repo)
  if not items then
    vim.notify(status_err, vim.log.levels.ERROR)
    return
  end

  local title = ('Git status: %s'):format(repo)
  vim.fn.setqflist({}, ' ', {
    items = items,
    title = title,
  })

  if vim.tbl_isempty(items) then
    vim.cmd 'cclose'
    vim.notify(('No modified or untracked files in %s.'):format(repo))
    return
  end

  vim.cmd 'copen'
  vim.notify(('Loaded %d file%s into quickfix from %s.'):format(#items, #items == 1 and '' or 's', repo))
end

function M.worktree()
  open_main_diff 'worktree'
end

function M.index()
  open_main_diff 'index'
end

function M.quickfix_worktree()
  open_quickfix_diffs 'worktree'
end

function M.quickfix_index()
  open_quickfix_diffs 'index'
end

function M.quickfix_status()
  populate_quickfix_from_status()
end

return M
