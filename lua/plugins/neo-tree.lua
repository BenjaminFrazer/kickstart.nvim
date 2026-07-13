-- Bridge kickstart's neo-tree spec into lazy's import path.
-- `lazy.setup('plugins')` auto-imports only `lua/plugins/*`, so this
-- re-exports the spec that lives in `lua/kickstart/plugins/neo-tree.lua`.
return require 'kickstart.plugins.neo-tree'
