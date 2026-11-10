-- pi's own completion (/commands, skill:, @file, paths) in the prompt pi opens
-- in nvim on Ctrl+G. The pi side is the pi-nvim-bridge package; it puts
-- PI_NVIM_BRIDGE in the editor's environment, so the plugin only loads in an
-- nvim that pi started. Pinned to the release pi-nvim-bridge is pinned to in
-- the dotfiles' pi/settings.json; move both together.
return {
  {
    'dabstractor/pi-nvim-bridge',
    tag = 'v0.1.3',
    cond = vim.env.PI_NVIM_BRIDGE ~= nil,
    lazy = false,
    config = function()
      require('pi-bridge').setup {
        -- pi runs `!` lines in bash, so complete them in bash too, rather than
        -- in $SHELL (zsh).
        shell = { prefer = 'bash' },
      }
    end,
  },
}
