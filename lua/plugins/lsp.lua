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
    -- Advertise that we can supply config dynamically (pyright relies on this
    -- to learn pythonPath via workspace/configuration).
    capabilities.workspace = capabilities.workspace or {}
    capabilities.workspace.configuration = true

    -- Respond to `workspace/configuration` requests by reading the matching
    -- key path out of the client's `settings` table. lspconfig used to do
    -- this for us; native vim.lsp does not.
    vim.lsp.handlers['workspace/configuration'] = function(_, result, ctx)
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      if not client or not result or not result.items then return {} end
      local out = {}
      for _, item in ipairs(result.items) do
        local value = client.config.settings or {}
        if item.section and item.section ~= '' then
          for part in string.gmatch(item.section, '[^.]+') do
            if type(value) ~= 'table' then value = vim.NIL; break end
            value = value[part]
            if value == nil then value = vim.NIL; break end
          end
        end
        table.insert(out, value)
      end
      return out
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

        -- Resolve the Python interpreter pyright should analyze against.
        -- Precedence: active venv ($VIRTUAL_ENV) > conda env ($CONDA_PREFIX)
        -- > project-local .venv / venv > $PYTHON > `python` on PATH.
        local function find_python()
          local function bin(dir)
            for _, p in ipairs({ dir .. '/bin/python', dir .. '/bin/python3', dir .. '/Scripts/python.exe' }) do
              if vim.fn.executable(p) == 1 then return p end
            end
          end
          if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= '' then
            local p = bin(vim.env.VIRTUAL_ENV); if p then return p end
          end
          if vim.env.CONDA_PREFIX and vim.env.CONDA_PREFIX ~= '' then
            local p = bin(vim.env.CONDA_PREFIX); if p then return p end
          end
          local root = get_root_dir({ 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' })
          for _, sub in ipairs({ '.venv', 'venv', '.env' }) do
            local p = bin(root .. '/' .. sub); if p then return p end
          end
          if vim.env.PYTHON and vim.fn.executable(vim.env.PYTHON) == 1 then
            return vim.env.PYTHON
          end
          if vim.fn.executable('python3') == 1 then return vim.fn.exepath('python3') end
          if vim.fn.executable('python') == 1 then return vim.fn.exepath('python') end
        end

        local python_path = find_python()

        vim.lsp.start({
          name = 'pyright',
          cmd = { pyright_cmd, '--stdio' },
          root_dir = get_root_dir({ 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' }),
          capabilities = capabilities,
          settings = {
            python = {
              pythonPath = python_path,
              venvPath = vim.env.VIRTUAL_ENV and vim.fn.fnamemodify(vim.env.VIRTUAL_ENV, ':h') or nil,
              analysis = {
                typeCheckingMode = 'basic',
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = 'workspace',
              },
            },
          },
        })
        if python_path then
          vim.schedule(function()
            vim.notify('pyright using python: ' .. python_path, vim.log.levels.INFO)
          end)
        end
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

    -- CMake LSP (cmake-language-server)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "cmake",
      callback = function()
        local cmake_cmd = mason_bin .. '/cmake-language-server'
        if not executable_exists(cmake_cmd) then
          cmake_cmd = 'cmake-language-server'
          if not executable_exists(cmake_cmd) then
            vim.notify('cmake-language-server not found. Install via Mason (:MasonInstall cmake-language-server) or pip', vim.log.levels.WARN)
            return
          end
        end

        vim.lsp.start({
          name = 'cmake',
          cmd = { cmake_cmd },
          root_dir = get_root_dir({ 'CMakeLists.txt', '.git' }),
          capabilities = capabilities,
          init_options = {
            buildDirectory = 'build',
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

    -- User commands replicating the familiar :Lsp* family (normally provided
    -- by nvim-lspconfig), implemented directly against vim.lsp.
    local function clients_for_buf(bufnr)
      return vim.lsp.get_clients({ bufnr = bufnr })
    end

    vim.api.nvim_create_user_command('LspInfo', function()
      local bufnr = vim.api.nvim_get_current_buf()
      local clients = clients_for_buf(bufnr)
      if vim.tbl_isempty(clients) then
        print('No LSP clients attached to buffer ' .. bufnr)
        return
      end
      local lines = { 'LSP clients attached to buffer ' .. bufnr .. ':' }
      for _, c in ipairs(clients) do
        table.insert(lines, ('  - %s (id=%d, root=%s)'):format(c.name, c.id, c.config.root_dir or '?'))
        table.insert(lines, '      cmd: ' .. table.concat(c.config.cmd or {}, ' '))
      end
      print(table.concat(lines, '\n'))
    end, { desc = 'Show LSP clients for current buffer' })

    vim.api.nvim_create_user_command('LspStop', function(opts)
      local bufnr = vim.api.nvim_get_current_buf()
      local targets = clients_for_buf(bufnr)
      if opts.args ~= '' then
        targets = vim.tbl_filter(function(c) return c.name == opts.args end, targets)
      end
      for _, c in ipairs(targets) do
        c.stop()
        vim.notify('Stopped LSP client: ' .. c.name)
      end
    end, {
      nargs = '?',
      desc = 'Stop LSP client(s) attached to current buffer',
      complete = function()
        return vim.tbl_map(function(c) return c.name end, clients_for_buf(vim.api.nvim_get_current_buf()))
      end,
    })

    vim.api.nvim_create_user_command('LspRestart', function(opts)
      local bufnr = vim.api.nvim_get_current_buf()
      local targets = clients_for_buf(bufnr)
      if opts.args ~= '' then
        targets = vim.tbl_filter(function(c) return c.name == opts.args end, targets)
      end
      local configs = {}
      for _, c in ipairs(targets) do
        table.insert(configs, vim.deepcopy(c.config))
        c.stop()
      end
      vim.defer_fn(function()
        for _, cfg in ipairs(configs) do
          vim.lsp.start(cfg)
          vim.notify('Restarted LSP client: ' .. cfg.name)
        end
      end, 500)
    end, {
      nargs = '?',
      desc = 'Restart LSP client(s) attached to current buffer',
      complete = function()
        return vim.tbl_map(function(c) return c.name end, clients_for_buf(vim.api.nvim_get_current_buf()))
      end,
    })

    vim.api.nvim_create_user_command('LspLog', function()
      vim.cmd('tabnew ' .. vim.lsp.get_log_path())
    end, { desc = 'Open the LSP log in a new tab' })

    vim.api.nvim_create_user_command('LspCapabilities', function()
      for _, c in ipairs(clients_for_buf(vim.api.nvim_get_current_buf())) do
        print('=== ' .. c.name .. ' ===')
        print(vim.inspect(c.server_capabilities))
      end
    end, { desc = 'Print server capabilities for attached LSP clients' })

    -- Point pyright at a specific Python interpreter for the current workspace.
    -- Equivalent to nvim-lspconfig's :PyrightSetPythonPath. Accepts either the
    -- interpreter path directly or a venv directory (will auto-resolve bin/python).
    vim.api.nvim_create_user_command('LspPyrightSetPython', function(opts)
      local path = vim.fn.expand(opts.args)
      if path == '' then
        path = vim.fn.input('Python interpreter: ', '', 'file')
        path = vim.fn.expand(path)
      end
      if path == '' then return end
      if vim.fn.isdirectory(path) == 1 then
        local candidate = path .. '/bin/python'
        if vim.fn.executable(candidate) == 1 then
          path = candidate
        else
          candidate = path .. '/Scripts/python.exe'
          if vim.fn.executable(candidate) == 1 then path = candidate end
        end
      end
      if vim.fn.executable(path) ~= 1 then
        vim.notify('Not an executable: ' .. path, vim.log.levels.ERROR)
        return
      end

      local pyrights = vim.tbl_filter(function(c) return c.name == 'pyright' end, vim.lsp.get_clients())
      if vim.tbl_isempty(pyrights) then
        vim.notify('No pyright client attached', vim.log.levels.WARN)
        return
      end
      for _, client in ipairs(pyrights) do
        client.settings = vim.tbl_deep_extend('force', client.settings or {}, {
          python = { pythonPath = path },
        })
        client.notify('workspace/didChangeConfiguration', { settings = client.settings })
        vim.notify(('pyright (id=%d): pythonPath = %s'):format(client.id, path))
      end
    end, {
      nargs = '?',
      complete = 'file',
      desc = 'Set pyright python interpreter path (workspace setting)',
    })
  end,
}