-- Native Neovim LSP configuration - no external plugins needed
-- Only using nvim-cmp for completion capabilities
return {
  -- Empty plugin just to ensure cmp_nvim_lsp is available for capabilities
  'hrsh7th/cmp-nvim-lsp',
  lazy = false,
  config = function()
    -- Get Mason bin path for installed servers
    local mason_bin = vim.fn.stdpath('data') .. '/mason/bin'
    
    -- Helper function to check if executable exists
    local function executable_exists(name)
      return vim.fn.executable(name) == 1
    end
    
    -- Helper to find project root
    local function get_root_dir(markers)
      local path = vim.fs.find(markers, { upward = true })[1]
      return path and vim.fs.dirname(path) or vim.fn.getcwd()
    end
    
    -- Setup capabilities for better completion
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local has_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
    if has_cmp then
      capabilities = vim.tbl_deep_extend('force', capabilities, cmp_nvim_lsp.default_capabilities())
    end

    -- Python LSP (pyright)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "python",
      callback = function()
        -- Try Mason's pyright first, then system pyright
        local pyright_cmd = mason_bin .. '/pyright-langserver'
        if not executable_exists(pyright_cmd) then
          pyright_cmd = 'pyright-langserver'
          if not executable_exists(pyright_cmd) then
            vim.notify('Pyright not found. Install with: npm install -g pyright', vim.log.levels.WARN)
            return
          end
        end
        
        vim.lsp.start({
          name = 'pyright',
          cmd = { pyright_cmd, '--stdio' },
          root_dir = get_root_dir({ 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' }),
          capabilities = capabilities,
          settings = {
            python = {
              analysis = {
                typeCheckingMode = 'basic',
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        })
      end,
    })

    -- Lua LSP (lua_ls)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "lua",
      callback = function()
        -- Try Mason's lua_ls first
        local lua_ls_cmd = mason_bin .. '/lua-language-server'
        if not executable_exists(lua_ls_cmd) then
          lua_ls_cmd = 'lua-language-server'
          if not executable_exists(lua_ls_cmd) then
            vim.notify('lua_ls not found. Install via Mason or package manager', vim.log.levels.WARN)
            return
          end
        end
        
        vim.lsp.start({
          name = 'lua_ls',
          cmd = { lua_ls_cmd },
          root_dir = get_root_dir({ '.luarc.json', '.git' }),
          capabilities = capabilities,
          settings = {
            Lua = {
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
      end,
    })

    -- C/C++ LSP (clangd)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "c", "cpp", "objc", "objcpp" },
      callback = function()
        local clangd_cmd = mason_bin .. '/clangd'
        if not executable_exists(clangd_cmd) then
          clangd_cmd = 'clangd'
          if not executable_exists(clangd_cmd) then
            vim.notify('clangd not found. Install via Mason or package manager', vim.log.levels.WARN)
            return
          end
        end
        
        vim.lsp.start({
          name = 'clangd',
          cmd = { clangd_cmd },
          root_dir = get_root_dir({ 'compile_commands.json', '.git' }),
          capabilities = capabilities,
        })
      end,
    })

    -- Setup keymaps when LSP attaches to a buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true }),
      callback = function(event)
        -- Helper for setting keymaps
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- Navigation keymaps
        map('gd', vim.lsp.buf.definition, 'Goto Definition')
        map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
        map('gI', vim.lsp.buf.implementation, 'Goto Implementation')
        map('gr', vim.lsp.buf.references, 'Goto References')
        map('gt', vim.lsp.buf.type_definition, 'Goto Type Definition')
        map('K', vim.lsp.buf.hover, 'Hover Documentation')
        map('<C-k>', vim.lsp.buf.signature_help, 'Signature Help')
        
        -- Action keymaps
        map('<leader>cr', vim.lsp.buf.rename, 'Rename')  -- Your preferred binding
        map('<leader>rn', vim.lsp.buf.rename, 'Rename')  -- Alternative binding
        map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
        map('<leader>f', vim.lsp.buf.format, 'Format')
        
        -- Workspace keymaps
        map('<leader>wa', vim.lsp.buf.add_workspace_folder, 'Add Workspace Folder')
        map('<leader>wr', vim.lsp.buf.remove_workspace_folder, 'Remove Workspace Folder')
        map('<leader>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, 'List Workspace Folders')
        
        -- Telescope integration for better UI (if available)
        local has_telescope, builtin = pcall(require, 'telescope.builtin')
        if has_telescope then
          map('<leader>cd', builtin.lsp_definitions, '[C]ode [D]efinition')
          map('<leader>cR', builtin.lsp_references, '[C]ode [R]eferences (Telescope)')  -- Changed to capital R
          map('<leader>ci', builtin.lsp_implementations, '[C]ode [I]mplementation')
          map('<leader>ct', builtin.lsp_type_definitions, '[C]ode [T]ype Definition')
          map('<leader>cs', builtin.lsp_document_symbols, '[C]ode [S]ymbols')
          map('<leader>cw', builtin.lsp_dynamic_workspace_symbols, '[C]ode [W]orkspace Symbols')
        end
        
        -- Diagnostic keymaps
        map('<leader>e', vim.diagnostic.open_float, 'Open Diagnostic Float')
        map('[d', vim.diagnostic.goto_prev, 'Previous Diagnostic')
        map(']d', vim.diagnostic.goto_next, 'Next Diagnostic')
        map('<leader>q', vim.diagnostic.setloclist, 'Set Location List')
        
        -- Document highlight on cursor hold
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = vim.api.nvim_create_augroup('lsp_document_highlight', { clear = false }),
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = vim.api.nvim_create_augroup('lsp_document_highlight_clear', { clear = false }),
            callback = vim.lsp.buf.clear_references,
          })
        end
      end,
    })

    -- Configure diagnostics display
    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = {
        border = 'rounded',
        source = 'always',
      },
    })

    -- Add diagnostic signs
    local signs = { Error = "✘", Warn = "▲", Hint = "⚡", Info = "ⓘ" }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end
  end,
}