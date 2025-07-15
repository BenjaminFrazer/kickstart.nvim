local M = {}

-- Function to find git root
M.find_git_root = function()
  local telescope_builtin = require('telescope.builtin')
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  
  if current_file == '' then
    current_dir = cwd
  else
    current_dir = vim.fn.fnamemodify(current_file, ':h')
  end

  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 then
    print 'Not a git repository. Searching on current working directory'
    return telescope_builtin.find_files { cwd = cwd }
  end
  telescope_builtin.find_files { cwd = git_root }
end

return M