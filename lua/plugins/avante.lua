return {
  'yetone/avante.nvim',
  event = 'VeryLazy',
  lazy = false,
  version = '*',
  opts = {
    file_selector = {
      provider = 'telescope',
      provider_opts = {
        file_ignore_patterns = {
          '__pycache__/',
          '%.pyc$',
          '%.pyo$',
          '.pytest_cache/',
          '.venv/',
          'venv/',
          '%.egg-info/',
          'node_modules/',
          '%.lock$',
          'dist/',
          'build/',
          '.next/',
          'coverage/',
          '.turbo/',
          '%.tsbuildinfo$',
          '.git/',
          '.DS_Store',
        },
        hidden = true,
        respect_gitignore = true,
      },
    },
  },
  build = 'make',
  dependencies = {
    'stevearc/dressing.nvim',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'nvim-telescope/telescope.nvim',
    'hrsh7th/nvim-cmp',
    'ibhagwan/fzf-lua',
    {
      'HakonHarnes/img-clip.nvim',
      event = 'VeryLazy',
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = true,
        },
      },
    },
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { 'markdown', 'Avante' },
      },
      ft = { 'markdown', 'Avante' },
    },
  },
}
