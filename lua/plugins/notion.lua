-- The integration token and both database IDs live in one 1Password item, in
-- fields `credential`, `tasks_db` and `notes_db`. `:NotionReauth <item id>`
-- names the item; its ID is kept in nvim's state directory, outside the repo.
-- 1Password asks for Touch ID if it is locked.
local item_file = vim.fn.stdpath 'state' .. '/notion-item'

local function saved_item()
  local ok, lines = pcall(vim.fn.readfile, item_file)
  return ok and lines[1] or nil
end

-- Database IDs, read from 1Password along with the token.
local databases

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

  local result = vim
    .system({
      'op',
      'item',
      'get',
      item,
      '--account',
      'my.1password.com',
      '--fields',
      'label=credential,label=tasks_db,label=notes_db',
      '--reveal',
    }, { text = true })
    :wait()
  local token, task, note = vim.trim(result.stdout or ''):match '^([^,]+),([%w-]+),([%w-]+)$'
  if result.code ~= 0 or not token then
    fail('Could not read the Notion token and databases from 1Password: ' .. vim.trim(result.stderr or ''))
    return false
  end

  require('notion.config').options.notion_token = token
  databases = { task = task, note = note }
  return true
end

local function reauth(args)
  local item = args.args ~= '' and args.args or nil
  if load(item) then
    if item then
      vim.fn.mkdir(vim.fs.dirname(item_file), 'p')
      vim.fn.writefile({ item }, item_file)
    end
    vim.notify 'Notion token and databases loaded from 1Password.'
  end
end

-- notion.nvim works against one database at a time and reads it from its
-- config on every call, so this points it at the right database just before
-- creating or browsing. Both databases must title their pages with a property
-- called `Name`, and be shared with the integration.
local function use_database(kind)
  if not databases and not load() then
    return
  end

  require('notion.config').options.database_id = databases[kind]
  return require 'notion.api'
end

-- With a title, create a page and open it; without one, pick a page to edit.
local function open(kind, title)
  local api = use_database(kind)
  if not api then
    return
  end

  if title and title ~= '' then
    api.create_page(title)
  else
    api.list_and_edit_pages()
  end
end

local function create(kind)
  vim.ui.input({ prompt = ('New %s: '):format(kind) }, function(title)
    open(kind, title)
  end)
end

local function command(kind)
  return function(args)
    open(kind, args.args)
  end
end

return {
  {
    'ALT-F4-LLC/notion.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'NotionTask', 'NotionNote', 'NotionReauth' },
    keys = {
      {
        '<leader>nt',
        function()
          create 'task'
        end,
        desc = 'Notion new task',
      },
      {
        '<leader>nT',
        function()
          open 'task'
        end,
        desc = 'Notion browse tasks',
      },
      {
        '<leader>nn',
        function()
          create 'note'
        end,
        desc = 'Notion new note',
      },
      {
        '<leader>nN',
        function()
          open 'note'
        end,
        desc = 'Notion browse notes',
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

      vim.api.nvim_create_user_command('NotionTask', command 'task', {
        nargs = '*',
        desc = 'Notion: create a task with the given title, or browse tasks',
      })
      vim.api.nvim_create_user_command('NotionNote', command 'note', {
        nargs = '*',
        desc = 'Notion: create a note with the given title, or browse notes',
      })
      vim.api.nvim_create_user_command('NotionReauth', reauth, {
        nargs = '?',
        desc = 'Notion: load the token and databases from a 1Password item (remembered once given)',
      })
    end,
  },
}
