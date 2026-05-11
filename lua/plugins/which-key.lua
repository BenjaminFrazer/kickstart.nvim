return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  config = function()
    require('which-key').setup {
      delay = 0,
      preset = 'modern',
    }

    -- Document existing key chains
    require('which-key').add {
      { '<leader>c', group = '[C]ode' },
      { '<leader>d', group = '[D]ocument' },
      { '<leader>h', group = 'Git [H]unk' },
      { '<leader>r', group = '[R]ename' },
      { '<leader>s', group = '[S]earch' },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>w', group = '[W]orkspace' },
      { '<leader>b', group = '[B]uffer' },
      { '<leader>f', group = '[F]ile' },
      { '<leader>p', group = '[P]roject' },
      { '<leader>q', group = '[Q]uarto' },
      { '<leader>x', group = 'Diagnosti[x]' },
    }
  end,
}