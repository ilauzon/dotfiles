local vim = vim

vim.g.mapleader = " "

-- disable netrw for nvim-tree

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

--

require('config.lazy')

-- nvim-tree

local nvim_tree = require("nvim-tree")
nvim_tree.setup({
    sort = {
        sorter = "case_sensitive",
    },
    view = {
        width = 30,
        float = {
            enable = true,
        },
    },
    renderer = {
        group_empty = true,
    },
    filters = {
        dotfiles = false,
    },
    git = {
        enable = true,
        ignore = false,
    }
})

vim.api.nvim_create_user_command('Ex', ':NvimTreeOpen .', { desc = 'nvim-tree open tree' })
vim.keymap.set('n', '<leader>e', ':NvimTreeOpen .<CR>', { desc = 'nvim-tree open tree' })

-- telescope

local function setup_telescope()
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Telescope show keymappings' })
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
    vim.keymap.set('n', '<leader>fs', builtin.lsp_document_symbols, { desc = 'Telescope document symbols' })
    vim.keymap.set('n', '<leader>fw', builtin.lsp_dynamic_workspace_symbols, { desc = 'Telescope workspace symbols' })
    vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Telescope diagnostics' })

    local telescope = require('telescope')
    local actions = require('telescope.actions')
    local project_actions = require("telescope._extensions.project.actions")
    local project_selected = false
    telescope.setup({
        defaults = {
            mappings = {
                i = {
                    ['<CR>'] = actions.select_default + actions.center,
                },
                n = {
                    ['<CR>'] = actions.select_default + actions.center,
                },
            },
            file_ignore_patterns = {
                ".venv",
                "__pycache__",
                "node_modules",
                ".git/",
                ".cache",
                ".vscode",
                "factorio",
            }
        },
        pickers = {
            find_files = {
                hidden = true,
                -- Optional: prevent searching inside the .git directory
                find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
            },
            buffers = {
                show_all_buffers = true,
                sort_lastused = true,
                mappings = {
                    i = {
                        ["<c-d>"] = "delete_buffer",
                    }
                }
            }
        },
        extensions = {
            project = {
                on_project_selected = function(prompt_bufnr)
                    project_actions.change_working_directory(prompt_bufnr, false)
                    vim.cmd('bufdo! bwipeout')
                    vim.diagnostic.reset()
                    builtin.find_files()
                end,
            }
        }
    })

    -- telescope - show projects on startup when called with no args

    local telescope_projects = telescope.extensions.project
    if vim.fn.argc() == 0 then
        vim.api.nvim_create_autocmd('VimEnter', {
            callback = function()
                telescope_projects.project { 'full' }
            end,
        })
    end

    vim.keymap.set('n', '<leader>fp', telescope_projects.project, { desc = 'Telescope find projects' })
end

setup_telescope()

-- debugger

local function setup_debugger()
    local dap = require("dap")

    dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
            command = "lldb",
            args = { "--port", "${port}" },
        }
    }

    local dapui = require("dapui")
    dapui.setup()

    vim.keymap.set('n', '<leader>dc', dap.continue, { desc = 'DAP continue' })
    vim.keymap.set('n', '<leader>ds', dap.step_over, { desc = 'DAP step over' })
    vim.keymap.set('n', '<leader>di', dap.step_into, { desc = 'DAP step into' })
    vim.keymap.set('n', '<leader>do', dap.step_out, { desc = 'DAP step out' })
    vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'DAP toggle breakpoint' })
    vim.keymap.set('n', '<leader>dt', dapui.toggle, { desc = 'DAP UI toggle' })

    dap.configurations.cpp = {
        {
            type = 'lldb',
            request = 'launch',
            name = "Launch",
            program = "${file}",
        }
    }
end

setup_debugger()

-- colorscheme

local function setup_colorscheme()
    vim.cmd.colorscheme "catppuccin-mocha"
end

setup_colorscheme()

-- lsp

local function setup_lsps()
    vim.lsp.config("clangd", {
        cmd = {
            'clangd',
            '--completion-style=detailed',
            '--background-index',
        }
    })
    vim.lsp.enable('clangd')

    vim.lsp.enable('lua_ls')

    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Perform LSP-suggested code action' })
    vim.keymap.set('n', 'grd', vim.lsp.buf.definition)
    vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        update_in_insert = true,
        severity_sort = true,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = true }),
        callback = function(args)
            vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = args.buf,
                callback = function()
                    vim.lsp.buf.format({ async = false, id = args.data.client_id })
                end,
            })
        end,
    })
end

setup_lsps()

-- that status bar at the bottom

require('lualine').setup()

-- custom actions for git repositories

local function get_target_path()
    if vim.fn.argc() == 0 then
        return nil
    end

    local arg = vim.fn.argv(0)
    local path = vim.fn.fnamemodify(arg, ":p")

    if vim.fn.isdirectory(path) == 1 then
        return path
    end

    return vim.fn.fnamemodify(path, ":h")
end

local function is_git_repo(path)
    local cmd = { "git", "-C", path, "rev-parse", "--is-inside-work-tree" }
    local result = vim.fn.system(cmd)
    return vim.v.shell_error == 0 and result:match("true")
end

local function load_all_files_as_bufs()
    -- 1. Get all tracked AND untracked files (excluding ignored ones)
    -- --cached: tracked files
    -- --others: untracked files
    -- --exclude-standard: respect .gitignore, .git/info/exclude, etc.
    local git_cmd = "git ls-files --cached --others --exclude-standard"
    local handle = io.popen(git_cmd)
    if not handle then return end
    local result = handle:read("*a")
    handle:close()

    local count = 0
    for file in result:gmatch("[^\r\n]+") do
        -- 2. Only load if it's a real file and NOT binary
        -- We check the first 1024 bytes for a null byte to detect binary
        if vim.fn.filereadable(file) == 1 then
            local f = io.open(file, "rb")
            if f then
                local bytes = f:read(1024) or ""
                f:close()

                if not bytes:find("\0") then
                    -- Load as hidden buffer to trigger LSP
                    vim.fn.bufload(vim.fn.bufadd(file))
                    count = count + 1
                end
            end
        end
    end
    vim.notify("LSP Project Scan: " .. count .. " files indexed.", vim.log.levels.INFO)
end

vim.keymap.set('n', '<leader>da', load_all_files_as_bufs, { desc = "Load all files into buffers for LSP (expensive!)" })
-- if the project is a git repository, open all files
local has_scanned = false
local function open_git_layout()
    -- Avoid re-running if layout already exists
    if vim.g.git_layout_opened then
        return
    end
    vim.g.git_layout_opened = true
    local file_dir = get_target_path()
    -- set cwd to that of given file
    vim.cmd("cd " .. file_dir)
end

-- Language servers that only scan open buffers.
local single_file_lsps = {
    ["clangd"] = true,
}
-- load all files in the repository into buffers for the LSP
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        -- Only run if the server is clangd and we haven't scanned yet this session
        local lsp = client.name
        if client and single_file_lsps[lsp] and not has_scanned then
            has_scanned = true
            vim.schedule(load_all_files_as_bufs)
        end
    end
})

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        local path = get_target_path()
        if not path then
            return
        end

        if is_git_repo(path) then
            open_git_layout()
        end
    end,
})

-- general

local function setup_general_settings()
    vim.o.tabstop = 8
    vim.o.expandtab = true
    vim.o.softtabstop = 0
    vim.o.shiftwidth = 4
    vim.o.smarttab = true

    vim.wo.number = true
    vim.wo.relativenumber = true
    vim.opt.signcolumn = 'yes'

    -- vim.g.netrw_bufsettings = 'noma nomod nobl ro'
    -- vim.g.netrw_liststyle = 3 -- expand folders without descending
end

setup_general_settings()
