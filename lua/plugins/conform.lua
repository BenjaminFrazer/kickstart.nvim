return {
  'stevearc/conform.nvim',
  lazy = false,
  keys = {
    {
      '<leader>bf',
      function()
        require('conform').format { async = true, lsp_fallback = true }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = false,
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'isort', 'black' },
      cpp = { '', '' },
    },
  },
}