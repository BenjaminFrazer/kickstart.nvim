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
    end,
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
