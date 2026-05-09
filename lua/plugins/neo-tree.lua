-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', { desc = 'NeoTree reveal' } },
  },
  opts = {
    event_handlers = {
      {
        event = "file_opened",
        handler = function()
          require("neo-tree.command").execute({ action = "close" })
        end,
      },
    },
    default_component_configs = {
      icon = {
        folder_closed = '+',
        folder_open = '-',
        folder_empty = '~',
        default = ' ',
      },
      git_status = {
        symbols = {
          added     = 'A',
          modified  = 'M',
          deleted   = 'D',
          renamed   = 'R',
          untracked = '?',
          ignored   = 'I',
          unstaged  = 'U',
          staged    = 'S',
          conflict  = 'C',
        },
      },
    },
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['<Tab>'] = 'toggle_node',
          ['P'] = 'toggle_preview',
        },
      },
    },
  },
}
