return {
  'folke/tokyonight.nvim',
  opts = {
    transparent = true,
    styles = {
      sidebars = 'transparent',
      floats = 'transparent',
    },
  },
  priority = 1000,
  init = function()
    vim.cmd.colorscheme 'tokyonight-night'
    vim.cmd.hi 'Comment gui=none'
  end,
}