-- The integration token and the databases live in one 1Password item: the
-- token in `credential`, and each database's ID in a field whose label ends in
-- `_db`, named by the rest of the label (`tasks_db` is `tasks`). Adding a field
-- adds a database. `:NotionReauth <item id>` names the item; its ID is kept in
-- nvim's state directory, outside the repo. 1Password asks for Touch ID if it
-- is locked.
local item_file = vim.fn.stdpath 'state' .. '/notion-item'

local function saved_item()
  local ok, lines = pcall(vim.fn.readfile, item_file)
  return ok and lines[1] or nil
end

-- Database name to ID, read from 1Password along with the token.
local databases

local function database_names()
  local names = databases and vim.tbl_keys(databases) or {}
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
local function load(item)
  item = item or saved_item()
  if not item then
    fail 'No 1Password item for Notion yet. Run :NotionReauth <item id>.'
    return false
  end

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

  require('notion.config').options.notion_token = token
  databases = found
  return true
end

local function reauth(args)
  local item = args.args ~= '' and args.args or nil
  if not load(item) then
    return
  end

  if item then
    vim.fn.mkdir(vim.fs.dirname(item_file), 'p')
    vim.fn.writefile({ item }, item_file)
  end
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
-- creating or browsing. Each database must title its pages with a property
-- called `Name`, and be shared with the integration.
local function use_database(name)
  require('notion.config').options.database_id = databases[name]
  return require 'notion.api'
end

-- Create a page and open it; without a title, ask for one.
local function new(name, title)
  with_database(name, function(db)
    if title and title ~= '' then
      use_database(db).create_page(title)
      return
    end

    vim.ui.input({ prompt = ('New page in %s: '):format(db) }, function(input)
      if input and input ~= '' then
        use_database(db).create_page(input)
      end
    end)
  end)
end

local function browse(name)
  with_database(name, function(db)
    use_database(db).list_and_edit_pages()
  end)
end

return {
  {
    'ALT-F4-LLC/notion.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'NotionNew', 'NotionBrowse', 'NotionReauth' },
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
      vim.api.nvim_create_user_command('NotionReauth', reauth, {
        nargs = '?',
        desc = 'Notion: load the token and databases from a 1Password item (remembered once given)',
      })
    end,
  },
}
