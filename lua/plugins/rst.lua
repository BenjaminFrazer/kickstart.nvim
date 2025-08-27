return {
  -- RST-specific configuration
  {
    'nvim-treesitter/nvim-treesitter',
    optional = true,
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, { 'rst' })
    end,
  },
  
  -- RST file type specific settings
  {
    'neovim/nvim-lspconfig',
    optional = true,
    config = function()
      -- Autocmd for RST files
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'rst',
        callback = function(event)
          -- Set up keymaps for RST files
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'RST: ' .. desc })
          end
          
          -- Tag navigation keymaps - use tjump for reliable behavior
          map('<C-]>', function()
            local word = vim.fn.expand '<cword>'
            vim.cmd('tjump ' .. word)
          end, 'Jump to tag (tjump)')
          
          map('gd', function()
            local word = vim.fn.expand '<cword>'
            -- Debug: show what word we're searching for
            vim.notify('Searching for tag: "' .. word .. '"')
            vim.cmd('tjump ' .. word)
          end, 'Go to definition (tjump)')
          
          map('g]', function()
            -- Always show list even if single match
            require('telescope.builtin').tags { 
              default_text = vim.fn.expand '<cword>',
              fname_width = 50,
            }
          end, 'List all matching tags')
          
          map('<C-t>', '<cmd>pop<CR>', 'Jump back from tag')
          
          -- Fuzzy search 
          map('<leader>cf', function()
            require('telescope.builtin').tags { 
              fname_width = 50,
            }
          end, 'Find tags (fuzzy)')
          
          -- Telescope tag search
          map('<leader>cd', function()
            local word = vim.fn.expand '<cword>'
            require('telescope.builtin').tags {
              default_text = word,
              fname_width = 50,
            }
          end, 'Go to definition (Telescope)')
          
          map('<leader>cR', function()
            -- Search for references using grep (since ctags doesn't provide references)
            local word = vim.fn.expand '<cword>'
            require('telescope.builtin').grep_string { search = word }
          end, 'Find references')
          
          -- Set options for better RST editing
          vim.opt_local.tabstop = 3
          vim.opt_local.shiftwidth = 3
          vim.opt_local.expandtab = true
          vim.opt_local.textwidth = 79
          
          -- Include hyphen and underscore in word definition for RST references
          -- This allows proper parsing of references like section-two and _introduction
          vim.opt_local.iskeyword:append('-')
          vim.opt_local.iskeyword:append('_')
          
          -- Enable spell checking for documentation
          vim.opt_local.spell = true
          vim.opt_local.spelllang = 'en_us'
        end,
      })
    end,
  },
}