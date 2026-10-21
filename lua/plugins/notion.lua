-- The integration token and the databases live in one 1Password item: the
-- token in `credential`, and each database's ID in a field whose label ends in
-- `_db`, named by the rest of the label (`tasks_db` is `tasks`). Adding a field
-- adds a database. `:NotionReauth <item id>` names the item and reads it; its
-- ID is kept in nvim's state directory, outside the repo. 1Password asks for
-- Touch ID if it is locked.
--
-- What 1Password gives is kept for later sessions: the token in the login
-- Keychain, under the item's ID, and the database IDs in the state directory.
-- So 1Password is read again only by :NotionReauth, when either is missing,
-- or when Notion rejects the token while listing pages.
local state = vim.fn.stdpath 'state'

local function read_state(name)
  local ok, lines = pcall(vim.fn.readfile, state .. '/' .. name)
  return ok and lines or nil
end

-- Readable only by you: the page titles come from your workspaces.
local function write_state(name, lines)
  vim.fn.mkdir(state, 'p')
  vim.fn.writefile(lines, state .. '/' .. name)
  vim.fn.setfperm(state .. '/' .. name, 'rw-------')
end

local function read_json(name)
  local lines = read_state(name)
  local ok, value = pcall(vim.json.decode, table.concat(lines or {}, '\n'))
  return ok and type(value) == 'table' and value or nil
end

local function saved_item()
  return (read_state 'notion-item' or {})[1]
end

local keychain_service = 'nvim-notion'

local function keychain_token(item)
  local result = vim.system({ 'security', 'find-generic-password', '-s', keychain_service, '-a', item, '-w' }, { text = true }):wait()
  return result.code == 0 and vim.trim(result.stdout) or nil
end

-- `security -i` reads the command from stdin, which keeps the token out of
-- the process list.
local function save_keychain_token(item, token)
  local command = ('add-generic-password -U -s "%s" -a "%s" -w "%s"\n'):format(keychain_service, item, token)
  vim.system({ 'security', '-i' }, { stdin = command }):wait()
end

-- Database name to ID.
local databases

-- Before the first command, the saved databases still complete.
local function database_names()
  local names = vim.tbl_keys(databases or read_json 'notion-databases.json' or {})
  table.sort(names)
  return names
end

-- Deferred: the first command runs through lazy.nvim's vim.cmd, which turns an
-- error message into a Lua error and a stack trace.
local function fail(message)
  vim.schedule(function()
    vim.notify(message, vim.log.levels.ERROR)
  end)
end

-- notion.nvim looks the token up from its config on every request, so
-- replacing it there takes effect immediately.
local function use(token, found)
  require('notion.config').options.notion_token = token
  databases = found
end

local function load_1password(item)
  local result = vim.system({ 'op', 'item', 'get', item, '--account', 'my.1password.com', '--format', 'json', '--reveal' }, { text = true }):wait()
  if result.code ~= 0 then
    fail('Could not read the Notion item from 1Password: ' .. vim.trim(result.stderr or ''))
    return false
  end

  local token
  local found = {}
  for _, field in ipairs(vim.json.decode(result.stdout).fields or {}) do
    local name = (field.label or ''):match '^(.+)_db$'
    if field.label == 'credential' then
      token = field.value
    elseif name and field.value and field.value ~= '' then
      found[name] = vim.trim(field.value)
    end
  end

  if not token or token == '' then
    fail 'The Notion item in 1Password has no `credential` field.'
    return false
  end
  if vim.tbl_isempty(found) then
    fail 'The Notion item in 1Password has no `*_db` fields.'
    return false
  end

  save_keychain_token(item, token)
  write_state('notion-databases.json', { vim.json.encode(found) })
  use(token, found)
  return true
end

local function load()
  local item = saved_item()
  if not item then
    fail 'No 1Password item for Notion yet. Run :NotionReauth <item id>.'
    return false
  end

  local found = read_json 'notion-databases.json'
  local token = found and not vim.tbl_isempty(found) and keychain_token(item)
  if token and token ~= '' then
    use(token, found)
    return true
  end
  return load_1password(item)
end

local function reauth(args)
  local item = args.args ~= '' and args.args or saved_item()
  if not item then
    fail 'No 1Password item for Notion yet. Run :NotionReauth <item id>.'
    return
  end
  if not load_1password(item) then
    return
  end

  write_state('notion-item', { item })
  vim.notify(('Notion token and databases loaded from 1Password: %s.'):format(table.concat(database_names(), ', ')))
end

-- Calls back with a database name: the given one, the only one, or a pick.
local function with_database(name, callback)
  if not databases and not load() then
    return
  end

  if name then
    if databases[name] then
      callback(name)
    else
      fail(('No Notion database `%s`; the item has %s.'):format(name, table.concat(database_names(), ', ')))
    end
    return
  end

  local names = database_names()
  if #names == 1 then
    callback(names[1])
    return
  end

  vim.ui.select(names, { prompt = 'Notion database' }, function(choice)
    if choice then
      callback(choice)
    end
  end)
end

-- notion.nvim works against one database at a time and reads it from its
-- config on every call, so this points it at the right database just before
-- creating a page. Each database must title its pages with a property called
-- `Name`, and be shared with the integration.
local function use_database(name)
  require('notion.config').options.database_id = databases[name]
  return require 'notion.api'
end

-- Each database's pages, by database ID, kept in the state directory. The
-- picker opens on the saved list at once while it refreshes in the
-- background, rather than waiting for notion.nvim to query the whole database.
local pages

local function saved_pages(id)
  pages = pages or read_json 'notion-pages.json' or {}
  return pages[id]
end

local function page_title(page)
  for _, property in pairs(page.properties or {}) do
    if property.type == 'title' then
      local parts = {}
      for _, part in ipairs(property.title or {}) do
        table.insert(parts, part.plain_text or '')
      end
      local title = table.concat(parts)
      return title ~= '' and title or 'Untitled'
    end
  end
  return 'Untitled'
end

-- Calls back with a database's pages, or nil and why not: the HTTP status
-- Notion answered with, or curl's error.
local function query(id, callback, cursor, found)
  found = found or {}
  require('plenary.curl').post('https://api.notion.com/v1/databases/' .. id .. '/query', {
    headers = {
      ['Authorization'] = 'Bearer ' .. require('notion.config').options.notion_token,
      ['Content-Type'] = 'application/json',
      ['Notion-Version'] = '2022-06-28',
    },
    body = vim.json.encode { page_size = 100, start_cursor = cursor },
    timeout = 10000,
    callback = vim.schedule_wrap(function(response)
      if response.status ~= 200 then
        callback(nil, response.status)
        return
      end

      local result = vim.json.decode(response.body)
      for _, page in ipairs(result.results or {}) do
        table.insert(found, { id = page.id, title = page_title(page) })
      end
      if result.has_more and type(result.next_cursor) == 'string' then
        query(id, callback, result.next_cursor, found)
      else
        callback(found)
      end
    end),
    on_error = vim.schedule_wrap(function(err)
      callback(nil, err.message)
    end),
  })
end

-- A rejected token is read again from 1Password, once, in case it changed.
local function refresh(name, callback, retried)
  local id = databases[name]
  if not id then
    return
  end

  query(id, function(found, reason)
    if found then
      table.sort(found, function(a, b)
        return a.title:lower() < b.title:lower()
      end)
      saved_pages(id)
      pages[id] = found
      write_state('notion-pages.json', { vim.json.encode(pages) })
    elseif reason == 401 and not retried and load_1password(saved_item()) then
      refresh(name, callback, true)
      return
    else
      fail(('Could not list the Notion pages in %s: %s'):format(name, reason))
    end

    if callback then
      callback(found)
    end
  end)
end

local function pick(list)
  vim.ui.select(list, {
    prompt = 'Notion page',
    format_item = function(page)
      return page.title
    end,
  }, function(page)
    if page then
      require('notion.api').edit_page(page.id)
    end
  end)
end

-- Set by new(), so the new page's database is refreshed once the page opens.
local created

-- Create a page and open it; without a title, ask for one.
local function new(name, title)
  with_database(name, function(db)
    local function create(input)
      created = db
      use_database(db).create_page(input)
    end

    if title and title ~= '' then
      create(title)
      return
    end

    vim.ui.input({ prompt = ('New page in %s: '):format(db) }, function(input)
      if input and input ~= '' then
        create(input)
      end
    end)
  end)
end

-- Only the first browse of a database waits for its pages.
local function browse(name)
  with_database(name, function(db)
    local list = saved_pages(databases[db])
    if list then
      pick(list)
      refresh(db)
      return
    end

    vim.notify(('Fetching the pages in %s...'):format(db))
    refresh(db, function(found)
      if found then
        pick(found)
      end
    end)
  end)
end

-- The ID of the last Notion page shown in a window, kept in nvim's state
-- directory so :NotionLast reopens it in a later session too.
local function last_page()
  return (read_state 'notion-last-page' or {})[1]
end

-- notion.nvim marks the buffer of an opened page with b:notion_page_id.
local function remember_page(args)
  local id = vim.b[args.buf].notion_page_id
  if not id then
    return
  end

  if id ~= last_page() then
    write_state('notion-last-page', { id })
  end
  if created then
    refresh(created)
    created = nil
  end
end

-- Switch to the page's buffer if it is still open, so unsaved edits survive
-- and notion.nvim does not create a second buffer with the same name.
local function open_last()
  local id = last_page()
  if not id then
    fail 'No Notion page opened yet.'
    return
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.b[buf].notion_page_id == id then
      vim.api.nvim_set_current_buf(buf)
      return
    end
  end

  if not databases and not load() then
    return
  end
  require('notion.api').edit_page(id)
end

return {
  {
    'ALT-F4-LLC/notion.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'NotionNew', 'NotionBrowse', 'NotionLast', 'NotionReauth' },
    keys = {
      {
        '<leader>nn',
        function()
          new()
        end,
        desc = 'Notion new page',
      },
      {
        '<leader>nb',
        function()
          browse()
        end,
        desc = 'Notion browse pages',
      },
      {
        '<leader>nl',
        function()
          open_last()
        end,
        desc = 'Notion last page',
      },
    },
    config = function()
      -- Set the options directly rather than through setup(), which warns
      -- when no token is configured; load() supplies the token on first use.
      local config = require 'notion.config'
      config.options = vim.tbl_deep_extend('force', config.defaults, {
        -- fzf-lua handles vim.ui.select.
        use_telescope = false,
      })

      -- The first word is the database only if one has that name, so
      -- `:NotionNew Fix the bug` picks a database and keeps the whole title.
      vim.api.nvim_create_user_command('NotionNew', function(args)
        if not databases and not load() then
          return
        end

        local first = args.fargs[1]
        if first and databases[first] then
          new(first, table.concat(args.fargs, ' ', 2))
        else
          new(nil, args.args)
        end
      end, {
        nargs = '*',
        complete = database_names,
        desc = 'Notion: create a page in a database ([db] [title])',
      })
      vim.api.nvim_create_user_command('NotionBrowse', function(args)
        browse(args.fargs[1])
      end, {
        nargs = '?',
        complete = database_names,
        desc = 'Notion: pick a page in a database to edit ([db])',
      })
      vim.api.nvim_create_user_command('NotionLast', open_last, {
        desc = 'Notion: reopen the last page that was open',
      })
      vim.api.nvim_create_autocmd('BufEnter', {
        group = vim.api.nvim_create_augroup('notion-last-page', {}),
        callback = remember_page,
        desc = 'Remember the last Notion page for :NotionLast, and list a new one',
      })
      vim.api.nvim_create_user_command('NotionReauth', reauth, {
        nargs = '?',
        desc = 'Notion: load the token and databases from a 1Password item (remembered once given)',
      })
    end,
  },
}
