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
  
  -- Check for RST reference patterns
  -- We want to trigger immediately after typing the backtick
  local in_ref = before_cursor:match(':ref:`[^`]*$')
  local in_doc = before_cursor:match(':doc:`[^`]*$')
  
  -- Also check if we just typed the backtick (empty completion)
  local just_started_ref = before_cursor:match(':ref:`$')
  local just_started_doc = before_cursor:match(':doc:`$')
  
  -- Don't trigger for standalone backticks or other contexts
  if not (in_ref or in_doc or just_started_ref or just_started_doc) then
    callback({ items = {}, isIncomplete = false })
    return
  end
  
  -- Get all tags from the tags file
  local items = {}
  local tag_list = vim.fn.taglist('.*')
  
  -- Create a set to avoid duplicates
  local seen = {}
  
  for _, tag in ipairs(tag_list) do
    local name = tag.name
    -- Skip tags that start with underscore (internal labels)
    -- Skip Lua function tags and other non-RST items
    if not seen[name] and not name:match('^_') and not name:match('%.') and not name:match('%[') then
      seen[name] = true
      
      -- Determine the kind based on tag info
      local kind = 'Reference'
      if tag.kind == 'c' then
        kind = 'Section'
      elseif tag.kind == 'T' then
        kind = 'Label'
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