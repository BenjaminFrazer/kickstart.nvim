-- Python step-through debugging (MATLAB-style breakpoints + stepping).
--
-- Stack:
--   * nvim-dap                -> the debug engine
--   * nvim-dap-ui             -> Workspace/Scopes/Stack panes (≈ MATLAB workspace)
--   * nvim-dap-python         -> debugpy adapter + Python launch configs
--   * nvim-dap-virtual-text   -> inline variable values next to your code
--
-- The debug *adapter* runs from Mason's debugpy, but the program being debugged
-- is launched with the project's own interpreter (same precedence as pyright:
-- $VIRTUAL_ENV > $CONDA_PREFIX > project .venv/venv/.env > $PYTHON > python).
return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'theHamsta/nvim-dap-virtual-text',
    'mfussenegger/nvim-dap-python',
    'williamboman/mason.nvim',
  },
  ft = { 'python' },
  keys = {
    -- F-keys for hot stepping (VSCode / MATLAB muscle memory)
    { '<F5>', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
    { '<F10>', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
    { '<F11>', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
    { '<S-F11>', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
    { '<S-F5>', function() require('dap').terminate() end, desc = 'Debug: Stop' },

    -- LazyVim-standard <leader>d scheme ----------------------------------
    -- Breakpoints
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Toggle Breakpoint' },
    {
      '<leader>dB',
      function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end,
      desc = 'Conditional Breakpoint',
    },
    -- Run control
    { '<leader>dc', function() require('dap').continue() end, desc = 'Continue' },
    { '<leader>dC', function() require('dap').run_to_cursor() end, desc = 'Run to Cursor' },
    {
      '<leader>da',
      function()
        require('dap').continue {
          before = function(config)
            local input = vim.fn.input 'Args: '
            config = vim.deepcopy(config)
            config.args = vim.split(input, ' ', { trimempty = true })
            return config
          end,
        }
      end,
      desc = 'Run with Args',
    },
    { '<leader>dl', function() require('dap').run_last() end, desc = 'Run Last' },
    -- Evaluate the current line (normal) or selection (visual) in the REPL,
    -- executed in the stopped frame. Output shows in the dap-ui console.
    {
      '<leader>dE',
      function() require('dap').repl.execute(vim.api.nvim_get_current_line()) end,
      desc = 'Eval Line in REPL',
    },
    {
      '<leader>dE',
      function()
        local region = vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = vim.fn.mode() })
        require('dap').repl.execute(table.concat(region, '\n'))
      end,
      mode = 'v',
      desc = 'Eval Selection in REPL',
    },
    { '<leader>dR', function() require('dap').restart() end, desc = 'Restart Session' },
    { '<C-S-F5>', function() require('dap').restart() end, desc = 'Debug: Restart' },
    { '<leader>dg', function() require('dap').goto_() end, desc = 'Go to Line (No Execute)' },
    { '<leader>dp', function() require('dap').pause() end, desc = 'Pause' },
    { '<leader>dt', function() require('dap').terminate() end, desc = 'Terminate' },
    -- Stepping (leader equivalents of the F-keys)
    { '<leader>di', function() require('dap').step_into() end, desc = 'Step Into' },
    { '<leader>do', function() require('dap').step_out() end, desc = 'Step Out' },
    { '<leader>dO', function() require('dap').step_over() end, desc = 'Step Over' },
    -- Stack navigation
    { '<leader>dj', function() require('dap').down() end, desc = 'Down (stack frame)' },
    { '<leader>dk', function() require('dap').up() end, desc = 'Up (stack frame)' },
    -- Inspect
    { '<leader>dr', function()
      local dap = require 'dap'
      dap.repl.toggle()
      -- If the REPL is now open, focus its window and enter insert mode so
      -- you can type immediately. If it was just closed, do nothing.
      local buf = vim.fn.bufnr 'dap-repl'
      if buf ~= -1 then
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == buf then
            vim.api.nvim_set_current_win(win)
            vim.cmd 'startinsert'
            break
          end
        end
      end
    end, desc = 'Toggle REPL' },
    { '<leader>dw', function() require('dap.ui.widgets').hover() end, desc = 'Widgets (hover)' },
    { '<leader>du', function() require('dapui').toggle() end, desc = 'Toggle UI' },
    { '<leader>dv', '<cmd>DapVirtualTextToggle<cr>', desc = 'Toggle Inline Variable Text' },
    {
      '<leader>de',
      function() require('dapui').eval(nil, { enter = true }) end,
      mode = { 'n', 'v' },
      desc = 'Eval expression',
    },
    -- Python: debug the test under the cursor
    { '<leader>dT', function() require('dap-python').test_method() end, desc = 'Test Method (Python)' },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- Resolve the project interpreter (mirrors lsp.lua's pyright precedence).
    local function find_python()
      local function bin(dir)
        for _, p in ipairs { dir .. '/bin/python', dir .. '/bin/python3', dir .. '/Scripts/python.exe' } do
          if vim.fn.executable(p) == 1 then return p end
        end
      end
      if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= '' then
        local p = bin(vim.env.VIRTUAL_ENV)
        if p then return p end
      end
      if vim.env.CONDA_PREFIX and vim.env.CONDA_PREFIX ~= '' then
        local p = bin(vim.env.CONDA_PREFIX)
        if p then return p end
      end
      local root = vim.fs.root(0, { 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' }) or vim.fn.getcwd()
      for _, sub in ipairs { '.venv', 'venv', '.env' } do
        local p = bin(root .. '/' .. sub)
        if p then return p end
      end
      if vim.env.PYTHON and vim.fn.executable(vim.env.PYTHON) == 1 then return vim.env.PYTHON end
      if vim.fn.executable 'python3' == 1 then return vim.fn.exepath 'python3' end
      if vim.fn.executable 'python' == 1 then return vim.fn.exepath 'python' end
      return 'python'
    end

    -- The interpreter that hosts the debugpy *adapter*. Prefer Mason's isolated
    -- debugpy so projects don't each need debugpy installed; fall back to the
    -- project interpreter if Mason hasn't installed it yet.
    local function debugpy_python()
      local mason_dbg = vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/bin/python'
      if vim.fn.executable(mason_dbg) == 1 then return mason_dbg end
      return find_python()
    end

    -- Best-effort: install debugpy via Mason if it's missing.
    pcall(function()
      local registry = require 'mason-registry'
      if registry.has_package 'debugpy' then
        local pkg = registry.get_package 'debugpy'
        if not pkg:is_installed() then pkg:install() end
      end
    end)

    require('dap-python').setup(debugpy_python())

    -- Always launch the debuggee with the project interpreter.
    require('dap-python').resolve_python = find_python

    -- Inline virtual text for variable values. Off by default (toggle with
    -- <leader>dv) — many find the inline previews noisy.
    require('nvim-dap-virtual-text').setup { enabled = false }

    -- Debugger UI: opens automatically with a session, closes when it ends.
    --
    -- NOTE: the dapui-embedded "repl" element won't accept insert mode in its
    -- pane (a dap-ui window quirk), so we use the standalone REPL via
    -- <leader>dr instead. We also drop the bottom tray (repl + console)
    -- entirely; program stdout/stderr shows in the REPL / launch terminal.
    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      layouts = {
        {
          position = 'left',
          size = 40,
          elements = {
            { id = 'scopes', size = 0.30 },
            { id = 'watches', size = 0.25 },
            { id = 'stacks', size = 0.25 },
            { id = 'breakpoints', size = 0.20 },
          },
        },
      },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- IPython-like repr evaluation ---------------------------------------
    -- nvim-dap renders an expandable variable *tree* whenever debugpy returns
    -- a non-zero variablesReference (i.e. for almost any object). debugpy
    -- already puts the clean __repr__ in resp.result, so this helper evaluates
    -- an expression and prints just that flat repr — like typing a name in
    -- IPython — instead of the tree.
    local function eval_repr(expr)
      expr = expr and vim.trim(expr) or ''
      if expr == '' then return end
      local session = dap.session()
      if not session then
        vim.notify('No active debug session', vim.log.levels.WARN)
        return
      end
      local frame = session.current_frame
      session:request('evaluate', {
        expression = expr,
        frameId = frame and frame.id,
        context = 'repl',
      }, function(err, resp)
        vim.schedule(function()
          local out = err and ('error: ' .. tostring(err.message or err))
            or (expr .. ' = ' .. resp.result)
          pcall(require('dap.repl').append, out)
          vim.notify(out, err and vim.log.levels.ERROR or vim.log.levels.INFO)
        end)
      end)
    end

    -- REPL command: type `p <expr>` (e.g. `p obj`) for a flat repr.
    require('dap.repl').commands.custom_commands['p'] = function(args)
      eval_repr(args)
    end

    -- <leader>dp: print repr of the expression under the cursor / selection.
    vim.keymap.set('n', '<leader>dp', function()
      eval_repr(vim.fn.expand '<cexpr>')
    end, { desc = 'Print repr (eval)' })
    vim.keymap.set('v', '<leader>dp', function()
      local region = vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = vim.fn.mode() })
      eval_repr(table.concat(region, ' '))
    end, { desc = 'Print repr (eval selection)' })

    -- Breakpoint signs.
    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn', numhl = '' })
    vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DiagnosticOk', linehl = 'Visual', numhl = '' })

    -- REPL: <C-p>/<C-n> walk command history (like a shell). If the cmp
    -- completion menu is open, fall back to cycling the menu instead.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'dap-repl',
      callback = function(ev)
        local repl = require 'dap.repl'
        local function nav(delta, hist)
          return function()
            local ok, cmp = pcall(require, 'cmp')
            if ok and cmp.visible() then
              if delta < 0 then
                cmp.select_prev_item()
              else
                cmp.select_next_item()
              end
            else
              hist()
            end
          end
        end
        vim.keymap.set('i', '<C-p>', nav(-1, repl.on_up), { buffer = ev.buf, desc = 'REPL: prev history' })
        vim.keymap.set('i', '<C-n>', nav(1, repl.on_down), { buffer = ev.buf, desc = 'REPL: next history' })
      end,
    })
  end,
}
