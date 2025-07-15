-- Neovim Configuration
-- This configuration is now organized in a modular structure for better maintainability

-- Load core modules
require('core.settings')    -- Basic vim settings and options
require('core.keymaps')     -- Key mappings
require('core.autocmds')    -- Auto commands
require('core.lazy')        -- Plugin manager setup

-- vim: ts=2 sts=2 sw=2 et