local vim = vim

vim.g.mapleader = " "

require('config.lazy')

-- telescope

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

-- colorscheme

vim.cmd.colorscheme "catppuccin-mocha"

-- lsp

vim.lsp.enable('clangd')

-- that status bar at the bottom

require('lualine').setup()

-- custom layout for git repositories

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

local function open_git_layout()
    -- Avoid re-running if layout already exists
    if vim.g.git_layout_opened then
        return
    end
    vim.g.git_layout_opened = true

    local file_dir = get_target_path()

    -- set cwd to that of given file
    vim.cmd("cd " .. file_dir)

    vim.api.nvim_create_autocmd("DiagnosticChanged", {
        once = true,
        callback = function()
            local trouble = require("trouble")

            trouble.open({
                mode = "symbols",
                focus = false,
                win = {
                    size = 0.3,
                    relative = "win",
                    position = "right",
                },
            })

        end,
    })

end

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

vim.o.tabstop = 8
vim.o.expandtab = true
vim.o.softtabstop = 0
vim.o.shiftwidth = 4
vim.o.smarttab = true

vim.wo.relativenumber = true
vim.opt.signcolumn = 'yes'

vim.g.netrw_bufsettings = 'noma nomod nobl ro'
vim.g.netrw_liststyle = 3 -- expand folders without descending
vim.g.netrw_banner = 0 -- hide banner
