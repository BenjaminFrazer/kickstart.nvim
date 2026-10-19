return {
  {
    'quarto-dev/quarto-nvim',
    dependencies = { 'jmbuhr/otter.nvim' },
    ft = { 'quarto', 'markdown' },
    opts = {
      lspFeatures = {
        enabled = true,
        chunks = 'curly',
        languages = { 'python', 'r', 'julia', 'bash' },
        diagnostics = {
          enabled = true,
          triggers = { 'BufWritePost' },
        },
        completion = {
          enabled = true,
        },
      },
      codeRunner = {
        enabled = true,
        default_method = 'slime',
      },
    },
    keys = {
      { '<leader>qp', function() require('quarto').quartoPreview() end,       desc = 'Quarto preview' },
      { '<leader>qq', function() require('quarto').quartoClosePreview() end,  desc = 'Quarto close preview' },
      { '<leader>qr', function() require('quarto.runner').run_cell() end,     desc = 'Run cell' },
      { '<leader>qa', function() require('quarto.runner').run_above() end,    desc = 'Run cells above' },
      { '<leader>qA', function() require('quarto.runner').run_all() end,      desc = 'Run all cells' },
      { '<leader>qe', function() require('quarto').activate() end,            desc = 'Activate quarto' },
    },
  },

  {
    'jmbuhr/otter.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {},
  },

  {
    'jpalardy/vim-slime',
    lazy = false, -- `keys` would otherwise lazy-load it after the FileType autocmd is needed
    init = function()
      vim.g.slime_target = 'neovim'
      vim.g.slime_no_mappings = true
      vim.g.slime_bracketed_paste = 1
    end,
    config = function()
      vim.g.slime_input_pid = false
      vim.g.slime_suggest_default = true
      vim.g.slime_menu_config = false
      vim.g.slime_neovim_ignore_unlisted = true
      vim.keymap.set('n', '<leader>cm', function()
        vim.print('job_id: ' .. vim.b.terminal_job_id)
      end, { desc = '[m]ark terminal' })
      vim.keymap.set('n', '<leader>cs', function()
        vim.fn.call('slime#config', {})
      end, { desc = '[s]et terminal' })
      -- Python buffers send `# %%` cells to the tmux pane right of nvim (quarto keeps the neovim target)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'python',
        callback = function(ev)
          vim.b[ev.buf].slime_target = 'tmux'
          vim.b[ev.buf].slime_cell_delimiter = '^# %%'
          vim.b[ev.buf].slime_config = { socket_name = vim.split(vim.env.TMUX or '', ',')[1], target_pane = '{right-of}' }
        end,
      })
    end,
    keys = {
      -- python3 from nvim's PATH, so an activated venv is used; `|| read` keeps the pane open on errors
      { '<leader>rr', function() vim.fn.system { 'tmux', 'split-window', '-h', '-d', '-c', vim.fn.getcwd(), vim.fn.exepath 'python3' .. ' -m IPython || read' } end, ft = 'python', desc = 'Start IPython pane' },
      { '<leader>rc', function() vim.fn['slime#send_cell']() vim.fn.search('^# %%', 'W') end, ft = 'python', desc = 'Send cell and advance' },
      { '<S-CR>', function() vim.fn['slime#send_cell']() vim.fn.search('^# %%', 'W') end, ft = 'python', desc = 'Send cell and advance' },
      -- %run -i keeps the REPL's variables and gives tracebacks with real line numbers
      { '<leader>rf', function() vim.cmd 'silent update' vim.fn['slime#send']('%run -i ' .. vim.fn.fnameescape(vim.fn.expand '%:p') .. '\n') end, ft = 'python', desc = 'Run file' },
      { '<leader>rl', '<Plug>SlimeLineSend', ft = 'python', desc = 'Send line' },
      { '<leader>rs', '<Plug>SlimeRegionSend', mode = 'x', ft = 'python', desc = 'Send selection' },
      { ']%', function() vim.fn.search('^# %%', 'W') end, ft = 'python', desc = 'Next cell' },
      { '[%', function() vim.fn.search('^# %%', 'bW') end, ft = 'python', desc = 'Previous cell' },
    },
  },

  {
    'benlubas/molten-nvim',
    enabled = false,
    version = '^1.0.0',
    build = ':UpdateRemotePlugins',
    init = function()
      vim.g.molten_image_provider = 'none'
      vim.g.molten_auto_open_output = true
      vim.g.molten_tick_rate = 200
    end,
  },
}
