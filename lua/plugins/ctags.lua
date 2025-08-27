return {
  -- Automatic tag generation
  {
    'ludovicchabant/vim-gutentags',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      -- Use universal-ctags
      vim.g.gutentags_ctags_executable = 'ctags-universal'
      
      -- Tag file location - store in project root
      -- Comment out to use project-local tags file instead of cache dir
      -- vim.g.gutentags_cache_dir = vim.fn.expand '~/.cache/nvim/tags'
      
      -- Only generate tags for certain file types
      vim.g.gutentags_exclude_filetypes = {
        'gitcommit',
        'gitconfig',
        'gitrebase',
        'svn',
        'csv',
        'txt',
        'markdown',
        'json',
      }
      
      -- Don't generate tags for files in these directories
      vim.g.gutentags_exclude_project_root = {
        '/usr/local',
        '/opt',
        vim.fn.expand '~',
      }
      
      -- Enable tag generation for RST files and other languages
      vim.g.gutentags_ctags_extra_args = {
        '--languages=ReStructuredText,Python,C,C++,Lua',
        '--kinds-ReStructuredText=*',
        '--fields=+l',
        '--extras=+q',
        '--sort=yes',
        '--excmd=number',  -- Use line numbers for all tags to ensure uniqueness
      }
      
      -- Define project root markers
      vim.g.gutentags_project_root = { '.git', '.hg', '.svn', '.bzr', '_darcs', '_build', 'build', 'env', 'venv' }
      
      -- Add gutentags status to statusline
      vim.g.gutentags_generate_on_new = 1
      vim.g.gutentags_generate_on_missing = 1
      vim.g.gutentags_generate_on_write = 1
      vim.g.gutentags_generate_on_empty_buffer = 0
    end,
  },
  
  -- Better tag navigation with Telescope
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      {
        '<leader>st',
        function()
          require('telescope.builtin').tags()
        end,
        desc = '[S]earch [T]ags',
      },
      {
        '<leader>sT',
        function()
          require('telescope.builtin').current_buffer_tags()
        end,
        desc = '[S]earch buffer [T]ags',
      },
    },
  },
}