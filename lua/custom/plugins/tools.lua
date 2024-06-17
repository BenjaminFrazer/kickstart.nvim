-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
--
local function find_git_root()
  local root = string.gsub(vim.fn.system 'git rev-parse --show-toplevel', '\n', '')
  ---local root = '~/dotfiles/'
  if vim.v.shell_error == 0 then
    require('telescope.builtin').find_files { cwd = root }
  else
    require('telescope.builtin').find_files()
  end
end

return { find_git_root = find_git_root }
