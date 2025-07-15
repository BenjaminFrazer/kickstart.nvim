return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = 'master',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    { 'nvim-telescope/telescope-file-browser.nvim' },
  },
  config = function()
    require('telescope').setup {
      pickers = {
        live_grep = {
          file_ignore_patterns = { '.git', '.venv' },
          additional_args = function(_)
            return { '--hidden' }
          end,
        },
        find_files = {
          file_ignore_patterns = { '.git', '.venv' },
          hidden = true,
        },
      },
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
      },
    }

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')
    pcall(require('telescope').load_extension, 'file_browser')

    -- See `:help telescope.builtin`
    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', builtin.current_buffer_fuzzy_find, { desc = '[S]earch current buffer' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>si', builtin.lsp_document_symbols, { desc = '[S]earch Symbols' })
    vim.keymap.set('n', '<leader>,', builtin.oldfiles, { desc = 'Search Recent Files' })
    vim.keymap.set('n', '<leader>so', builtin.vim_options, { desc = '[S]earch [O]ptions' })
    vim.keymap.set('n', '<leader><leader>', function()
      -- Get git root directory
      local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
      if vim.v.shell_error ~= 0 then
        -- Not in a git repo, use current working directory
        git_root = vim.fn.getcwd()
      end
      
      -- Use oldfiles to get recently edited files, then filter by git root
      builtin.oldfiles {
        cwd = git_root,
        cwd_only = true,
        -- This will show only files from the current workspace
        only_cwd = true,
      }
    end, { desc = 'Recent files in workspace' })

    -- Advanced keymaps
    vim.keymap.set('n', '<leader>/', function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })

    vim.keymap.set('n', '<leader>sn', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[S]earch [N]eovim files' })
  end,
}