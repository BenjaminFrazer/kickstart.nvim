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
          
          -- Smart jump: handles both :ref: tags and :doc: references
          local function smart_jump()
            -- First check if we're on a :doc: reference
            local line = vim.api.nvim_get_current_line()
            local col = vim.fn.col('.')
            
            -- Look for :doc:`...` pattern in the line
            local doc_start = line:find(':doc:`', 1, true)
            if doc_start and col >= doc_start then
              -- Extract the document path between backticks
              local doc_pattern = ':doc:`([^`]+)`'
              local doc_path = line:match(doc_pattern, doc_start)
              
              if doc_path then
                -- Handle the document path (may include subdirectories)
                local file_path = doc_path .. '.rst'
                
                -- Check if file exists
                if vim.fn.filereadable(file_path) == 1 then
                  vim.cmd('edit ' .. vim.fn.fnameescape(file_path))
                  return
                else
                  vim.notify('Document not found: ' .. file_path, vim.log.levels.WARN)
                  return
                end
              end
            end
            
            -- Otherwise, do regular tag jump for :ref: references
            local word = vim.fn.expand '<cword>'
            -- Remove leading underscore for RST labels (definitions use _, references don't)
            local search_word = word:gsub('^_', '')
            -- Get exact matches for the tag name
            local tag_list = vim.fn.taglist(search_word)
            
            -- Filter for exact matches only
            local exact_matches = {}
            for _, tag in ipairs(tag_list) do
              if tag.name == search_word then
                table.insert(exact_matches, tag)
              end
            end
            
            if #exact_matches == 0 then
              vim.notify('No tags found for: ' .. search_word, vim.log.levels.WARN)
            elseif #exact_matches == 1 then
              -- Single match - jump immediately
              vim.cmd('tag ' .. vim.fn.fnameescape(search_word))
            else
              -- Multiple matches - use telescope for selection
              require('telescope.builtin').tags {
                default_text = search_word,  -- Use cleaned word without underscore
                fname_width = 50,
                show_line = false,  -- Line numbers don't show well with number-based tags
                only_sort_tags = true,  -- Sort by tag name relevance
              }
            end
          end
          
          -- Tag navigation keymaps - now handles both :ref: and :doc:
          map('<C-]>', smart_jump, 'Jump to tag/doc (smart)')
          map('gd', smart_jump, 'Go to definition/document (smart)')
          
          map('g]', function()
            local word = vim.fn.expand '<cword>'
            -- Always show list with telescope
            require('telescope.builtin').tags {
              default_text = word,  -- Just the word, no regex anchors
              fname_width = 50,
              show_line = false,
            }
          end, 'List all matching tags')
          
          map('<C-t>', '<cmd>pop<CR>', 'Jump back from tag')
          
          -- Fuzzy search 
          map('<leader>cf', function()
            require('telescope.builtin').tags { 
              fname_width = 50,
            }
          end, 'Find tags (fuzzy)')
          
          -- Leader cd - use smart jump for both :ref: and :doc:
          map('<leader>cd', smart_jump, 'Go to definition/document (smart)')
          
          map('<leader>cR', function()
            -- Search for RST references to the current word/label
            local word = vim.fn.expand '<cword>'
            
            -- RST labels start with _ in definitions but not in references
            -- If we're on _section-two, search for references to section-two
            -- If we're on section-two, also search for that
            local label_name = word:gsub('^_', '')  -- Remove leading underscore if present
            
            -- Debug (uncomment to see what's being searched)
            -- vim.notify('Label: "' .. label_name .. '" (from "' .. word .. '")')
            
            -- Search for all RST reference patterns to this label
            -- We'll use regex to catch multiple patterns at once
            local patterns = {
              ':ref:`' .. label_name,      -- :ref:`section-two`
              ':doc:`[^`]*' .. label_name, -- :doc:`path/section-two`
              '`' .. label_name .. '`_',   -- `section-two`_
              label_name .. '_',            -- section-two_ (standalone reference)
              '<' .. label_name .. '>',     -- <section-two>
            }
            
            -- Join patterns with | for OR matching
            local pattern = table.concat(patterns, '|')
            
            require('telescope.builtin').grep_string { 
              search = pattern,
              use_regex = true,
              -- Exclude tag files and other generated files
              additional_args = function()
                return { 
                  '--glob', '!tags',
                  '--glob', '!.tags',
                  '--glob', '!*.tags',
                  '--glob', '!.rst_tags',
                  '--glob', '!_build',
                  '--glob', '!*.pyc',
                  '--type', 'rst',  -- Only search RST files
                }
              end,
              prompt_title = 'RST References to: ' .. label_name,
            }
          end, 'Find RST references')
          
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