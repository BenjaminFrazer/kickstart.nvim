return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  config = function()
    require('which-key').setup()

    -- Document existing key chains
    require('which-key').add {
      { '<leader>c', desc = '[C]ode' },
      { '<leader>d', desc = '[D]ocument' },
      { '<leader>h', desc = 'Git [H]unk' },
      { '<leader>r', desc = '[R]ename' },
      { '<leader>s', desc = '[S]earch' },
      { '<leader>t', desc = '[T]oggle' },
      { '<leader>w', desc = '[W]orkspace' },
      { '<leader>b', desc = '[B]uffer' },
      { '<leader>f', desc = '[F]ile' },
      { '<leader>p', desc = '[P]roject' },
      { '<leader>x', desc = 'Diagnosti[x]' },
    }
  end,
}