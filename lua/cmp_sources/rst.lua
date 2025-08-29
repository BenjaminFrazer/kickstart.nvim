-- Custom RST completion source for nvim-cmp
local source = {}

source.new = function()
  return setmetatable({}, { __index = source })
end

source.is_available = function()
  -- Only available in RST files
  return vim.bo.filetype == 'rst'
end

source.get_trigger_characters = function()
  -- Trigger completion when typing backtick after :ref: or :doc:
  return { '`' }
end

source.get_keyword_pattern = function()
  -- Match word characters and hyphens after :ref:` or :doc:`
  return [[\%(:ref:`\|:doc:`\)\zs[a-zA-Z0-9_-]*]]
end

source.complete = function(self, params, callback)
  local line = params.context.cursor_line
  local col = params.context.cursor.col
  
  -- Check if we're in a context where RST references make sense
  local before_cursor = line:sub(1, col - 1)
  
  -- Check for RST reference patterns and determine type
  local in_ref = before_cursor:match(':ref:`[^`]*$')
  local in_doc = before_cursor:match(':doc:`[^`]*$')
  
  -- Also check if we just typed the backtick (empty completion)
  local just_started_ref = before_cursor:match(':ref:`$')
  local just_started_doc = before_cursor:match(':doc:`$')
  
  local completion_type = nil
  if in_ref or just_started_ref then
    completion_type = 'ref'
  elseif in_doc or just_started_doc then
    completion_type = 'doc'
  else
    callback({ items = {}, isIncomplete = false })
    return
  end
  
  local items = {}
  
  if completion_type == 'ref' then
    -- For :ref: - provide labels from tags
    local tag_list = vim.fn.taglist('.*')
    local seen = {}
    
    for _, tag in ipairs(tag_list) do
      local name = tag.name
      -- Only include RST labels and sections, skip internal ones
      if not seen[name] and not name:match('^_') and not name:match('%.') and not name:match('%[') then
        -- Only include actual RST tags (sections and labels)
        if tag.kind == 'T' or tag.kind == 'c' or tag.kind == 's' then
          seen[name] = true
          
          local kind = 'Label'
          if tag.kind == 'c' then
            kind = 'Chapter'
          elseif tag.kind == 's' then
            kind = 'Section'
          end
          
          table.insert(items, {
            label = name,
            kind = vim.lsp.protocol.CompletionItemKind.Reference,
            detail = kind .. ' in ' .. (tag.filename or 'unknown'),
            documentation = tag.cmd and ('Line: ' .. tag.cmd:match('%d+')) or '',
            insertText = name,
          })
        end
      end
    end
    
  elseif completion_type == 'doc' then
    -- For :doc: - provide list of RST documents in project
    local cwd = vim.fn.getcwd()
    
    -- Find all .rst files in the project
    local rst_files = vim.fn.glob('**/*.rst', false, true)
    
    for _, filepath in ipairs(rst_files) do
      -- Convert to relative path without extension
      local rel_path = filepath:gsub('%.rst$', '')
      
      -- Skip common non-document files
      if not rel_path:match('^_') and not rel_path:match('/_%') then
        -- Get the file's first heading if possible
        local first_line = ''
        local file = io.open(filepath, 'r')
        if file then
          -- Read first few lines to find title
          for i = 1, 10 do
            local line = file:read()
            if not line then break end
            -- Check if it's a heading (has underline on next line)
            if line:match('^[^=%-~]+$') and #line > 0 then
              local next = file:read()
              if next and (next:match('^=+$') or next:match('^%-+$')) then
                first_line = line
                break
              end
            end
          end
          file:close()
        end
        
        table.insert(items, {
          label = rel_path,
          kind = vim.lsp.protocol.CompletionItemKind.File,
          detail = 'Document',
          documentation = first_line ~= '' and ('Title: ' .. first_line) or filepath,
          insertText = rel_path,
        })
      end
    end
  end
  
  -- Sort items alphabetically
  table.sort(items, function(a, b)
    return a.label < b.label
  end)
  
  callback({ items = items, isIncomplete = false })
end

source.resolve = function(self, completion_item, callback)
  callback(completion_item)
end

-- Register the source
require('cmp').register_source('rst_refs', source.new())

return source