return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    { 'j-hui/fidget.nvim', opts = {} },
    { 'folke/neodev.nvim', opts = {} },
  },
  config = function()
    -- Setup mason first
    require('mason').setup()
    
    -- Setup mason-lspconfig
    require('mason-lspconfig').setup({
      ensure_installed = { 'lua_ls', 'pyright', 'clangd', 'marksman' },
    })
    
    -- Manually ensure formatters are installed
    vim.defer_fn(function()
      local registry = require('mason-registry')
      local function ensure_installed(name)
        local ok, pkg = pcall(registry.get_package, name)
        if ok and not pkg:is_installed() then
          vim.notify('Installing ' .. name)
          pkg:install()
        end
      end
      
      -- Install formatters
      ensure_installed('stylua')
      ensure_installed('black')
      ensure_installed('isort')
    end, 100)
    
    -- Setup capabilities for nvim-cmp
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local has_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
    if has_cmp then
      capabilities = vim.tbl_deep_extend('force', capabilities, cmp_nvim_lsp.default_capabilities())
    end
    
    -- Configure individual servers
    local lspconfig = require('lspconfig')
    
    -- Lua
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          completion = {
            callSnippet = 'Replace',
          },
          diagnostics = {
            globals = { 'vim' },
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file('', true),
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    })
    
    -- Python
    lspconfig.pyright.setup({
      capabilities = capabilities,
    })
    
    -- C/C++
    lspconfig.clangd.setup({
      capabilities = capabilities,
    })
    
    -- Markdown
    lspconfig.marksman.setup({
      capabilities = capabilities,
    })
    
    -- Configure LSP keymaps on attach
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- LSP keymaps
        map('<leader>cd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
        map('<leader>cR', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        map('<leader>cI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
        map('<leader>ct', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
        map('<leader>si', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        map('<leader>sp', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
        map('<leader>cr', vim.lsp.buf.rename, '[R]e[n]ame')
        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
        map('K', vim.lsp.buf.hover, 'Hover Documentation')
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        -- Highlight references
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            callback = vim.lsp.buf.clear_references,
          })
        end

        -- Inlay hints toggle
        if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })
  end,
}