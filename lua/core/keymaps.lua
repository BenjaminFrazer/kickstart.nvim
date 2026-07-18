-- Clear search highlight on pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Split navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Project compile
vim.keymap.set('n', '<leader>pc', '<cmd>make<cr>', { desc = 'compile project' })

-- File browser
vim.keymap.set('n', '<leader>.', ':Telescope file_browser path=%:p:h select_buffer=true<CR>', { desc = 'File browser' })

-- Copy relative path
vim.api.nvim_create_user_command('CopyRelPath', "call setreg('+', expand('%'))", {})
vim.keymap.set('n', '<leader>fy', '<cmd>CopyRelPath<cr>', { desc = 'Yank relative path' })

-- Quick one-line command runner: single transient prompt at the bottom,
-- runs async (non-blocking), output shown transiently via vim.notify.
vim.keymap.set('n', '<leader>!', function()
  vim.ui.input({ prompt = '❯ ' }, function(cmd)
    if not cmd or cmd == '' then return end
    vim.system({ vim.o.shell, '-c', cmd }, { text = true }, function(obj)
      vim.schedule(function()
        local out = vim.trim((obj.stdout or '') .. (obj.stderr or ''))
        if out == '' then out = ('[exit %d]'):format(obj.code) end
        vim.notify(out, obj.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
      end)
    end)
  end)
end, { desc = 'Run shell command' })