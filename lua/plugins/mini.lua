return {
  'echasnovski/mini.nvim',
  config = function()
    -- Better Around/Inside textobjects
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings
    require('mini.surround').setup({
      mappings = {
        add = 'ys', -- Add surrounding in Normal and Visual modes
        delete = 'ds', -- Delete surrounding
        find = 'fs', -- Find surrounding (to the right)
        find_left = 'Fs', -- Find surrounding (to the left)
        highlight = 'hs', -- Highlight surrounding
        replace = 'cs', -- Replace surrounding
        update_n_lines = 'sn', -- Update `n_lines`
        
        -- Add this to make visual mode work with S
        suffix_last = 'l', -- Suffix to search with "prev" method
        suffix_next = 'n', -- Suffix to search with "next" method
      },
      
      -- Make it work in visual mode with S (capital S)
      custom_surroundings = nil,
      highlight_duration = 500,
      n_lines = 20,
      respect_selection_type = false,
      search_method = 'cover',
      silent = false,
    })
    
    -- Add visual mode mapping for S
    vim.keymap.set('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })
    
    -- Optional: Add some common surroundings shortcuts
    vim.keymap.set('v', 'S(', [[:<C-u>lua MiniSurround.add('visual', { char = '(' })<CR>]], { silent = true })
    vim.keymap.set('v', 'S)', [[:<C-u>lua MiniSurround.add('visual', { char = ')' })<CR>]], { silent = true })
    vim.keymap.set('v', 'S[', [[:<C-u>lua MiniSurround.add('visual', { char = '[' })<CR>]], { silent = true })
    vim.keymap.set('v', 'S]', [[:<C-u>lua MiniSurround.add('visual', { char = ']' })<CR>]], { silent = true })
    vim.keymap.set('v', 'S{', [[:<C-u>lua MiniSurround.add('visual', { char = '{' })<CR>]], { silent = true })
    vim.keymap.set('v', 'S}', [[:<C-u>lua MiniSurround.add('visual', { char = '}' })<CR>]], { silent = true })
    vim.keymap.set('v', 'S"', [[:<C-u>lua MiniSurround.add('visual', { char = '"' })<CR>]], { silent = true })
    vim.keymap.set('v', "S'", [[:<C-u>lua MiniSurround.add('visual', { char = "'" })<CR>]], { silent = true })
    vim.keymap.set('v', 'S`', [[:<C-u>lua MiniSurround.add('visual', { char = '`' })<CR>]], { silent = true })

    -- Simple and easy statusline
    local statusline = require 'mini.statusline'
    statusline.setup { use_icons = vim.g.have_nerd_font }

    -- Custom statusline section
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end
  end,
}