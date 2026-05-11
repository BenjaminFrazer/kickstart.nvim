-- Quarto: use markdown treesitter parser and auto-activate otter
vim.treesitter.language.register('markdown', 'quarto')
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'quarto',
  callback = function()
    require('quarto').activate()
  end,
})

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})