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

local function create_timestamped_file()
  -- Get current timestamp in YYMMDDHHMM format
  local timestamp = os.date '%y%m%d%H%M'

  -- Prompt user for filename
  vim.ui.input({ prompt = 'Enter filename: ' }, function(filename)
    if filename and filename ~= '' then
      local full_name = timestamp .. '_' .. filename
      -- Create the file (edit it)
      vim.cmd('edit ' .. vim.fn.fnameescape(full_name))
    end
  end)
end

return { find_git_root = find_git_root, create_timestamped_file = create_timestamped_file }
