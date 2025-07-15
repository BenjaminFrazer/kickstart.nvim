-- Gitsigns keymaps (from kickstart.plugins.gitsigns)
local gitsigns = require('gitsigns')

vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
vim.keymap.set('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
vim.keymap.set('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'git [u]ndo stage hunk' })
vim.keymap.set('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
vim.keymap.set('n', '<leader>hb', gitsigns.blame_line, { desc = 'git [b]lame line' })
vim.keymap.set('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
vim.keymap.set('n', '<leader>hD', function()
  gitsigns.diffthis '@'
end, { desc = 'git [D]iff against last commit' })

-- Toggles
vim.keymap.set('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
vim.keymap.set('n', '<leader>tD', gitsigns.toggle_deleted, { desc = '[T]oggle git show [D]eleted' })

-- Visual mode
vim.keymap.set('v', '<leader>hs', function()
  gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
end, { desc = 'stage git hunk' })
vim.keymap.set('v', '<leader>hr', function()
  gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
end, { desc = 'reset git hunk' })

-- Text object
vim.keymap.set({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'select git hunk' })