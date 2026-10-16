-- The integration token and both database IDs live in one 1Password item,
-- named here only by its ID: fields `credential`, `tasks_db` and `notes_db`.
-- 1Password asks for Touch ID if it is locked.
local item = 'li6figzqkesoe7ewyjond4cdle'

local function op_fields(fields)
  return { 'op', 'item', 'get', item, '--account', 'my.1password.com', '--fields', fields, '--reveal' }
end

local token_cmd = op_fields 'label=credential'

-- Database IDs, read from 1Password the first time a command needs them.
local databases

local function load_databases()
  local result = vim.system(op_fields 'label=tasks_db,label=notes_db', { text = true }):wait()
  local task, note = vim.trim(result.stdout or ''):match '^([%w-]+),([%w-]+)$'
  if result.code ~= 0 or not task then
    vim.notify('Could not read the Notion database IDs from 1Password: ' .. vim.trim(result.stderr or ''), vim.log.levels.ERROR)
    return false
  end

  databases = { task = task, note = note }
  return true
end

-- notion.nvim reads the token once at setup but looks it up from its config
-- on every request, so replacing it there takes effect immediately.
local function reauth()
  local result = vim.system(token_cmd, { text = true }):wait()
  local token = vim.trim(result.stdout or '')
  if result.code ~= 0 or token == '' then
    vim.notify('Could not read the Notion token from 1Password: ' .. vim.trim(result.stderr or ''), vim.log.levels.ERROR)
    return
  end

  require('notion.config').options.notion_token = token
  if load_databases() then
    vim.notify 'Notion token and databases reloaded from 1Password.'
  end
end

-- notion.nvim works against one database at a time and reads it from its
-- config on every call, so this points it at the right database just before
-- creating or browsing. Both databases must title their pages with a property
-- called `Name`, and be shared with the integration.
local function use_database(kind)
  if not databases and not load_databases() then
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
      require('notion').setup {
        -- Runs once, when a Notion command first loads the plugin.
        notion_token_cmd = token_cmd,
        -- fzf-lua handles vim.ui.select.
        use_telescope = false,
      }

      vim.api.nvim_create_user_command('NotionTask', command 'task', {
        nargs = '*',
        desc = 'Notion: create a task with the given title, or browse tasks',
      })
      vim.api.nvim_create_user_command('NotionNote', command 'note', {
        nargs = '*',
        desc = 'Notion: create a note with the given title, or browse notes',
      })
      vim.api.nvim_create_user_command('NotionReauth', reauth, {
        desc = 'Notion: reload the token and databases from 1Password',
      })
    end,
  },
}
