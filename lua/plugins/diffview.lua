return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
  keys = {
    { '<leader>gd', '<cmd>DiffviewOpen<cr>',            desc = 'Diff view' },
    { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>',   desc = 'File history' },
    { '<leader>gH', '<cmd>DiffviewFileHistory<cr>',     desc = 'Repo history' },
    { '<leader>gx', '<cmd>DiffviewClose<cr>',           desc = 'Close diff view' },
  },
  opts = {
    use_icons = false,
    keymaps = {
      view = { { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diff view' } } },
      file_panel = { { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diff view' } } },
      file_history_panel = { { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diff view' } } },
    },
  },
}
