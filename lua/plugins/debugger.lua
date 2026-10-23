return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text",
        "mason-org/mason.nvim",
    },
    config = function()
        local dap = require('dap')

        local dapui = require('dapui')
        require("nvim-dap-virtual-text").setup {
            commented = true,
        }

        dapui.setup()

        dap.listeners.before.attach.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
            dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
            dapui.close()
        end

        -- .NET debugger. Mason puts netcoredbg on Neovim's PATH.
        dap.adapters.coreclr = {
            type = "executable",
            command = "netcoredbg",
            args = { "--interpreter=vscode" },
        }

        -- Skipped when headless so scripted runs don't exit partway through the download.
        if #vim.api.nvim_list_uis() > 0 then
            local registry = require("mason-registry")
            -- The refresh callback runs where most editor functions aren't allowed, so schedule it.
            registry.refresh(vim.schedule_wrap(function()
                local ok, netcoredbg = pcall(registry.get_package, "netcoredbg")
                if not ok then
                    vim.notify("Mason package 'netcoredbg' not found; .NET debugging is unavailable", vim.log.levels.WARN)
                elseif not netcoredbg:is_installed() and not netcoredbg:is_installing() then
                    netcoredbg:install()
                end
            end))
        end

        local dotnet = require("dotnet")
        vim.keymap.set('n', '<Leader>db', dotnet.build_solution_or_project, { desc = "Build .NET solution or project" })
        vim.keymap.set('n', '<Leader>dd', dotnet.debug_project, { desc = "Build and debug .NET project" })

        vim.keymap.set('n', '<Leader>dt', dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
        vim.keymap.set('n', '<Leader>dc', dap.continue, { desc = "Continue debugging" })
        vim.keymap.set('n', '<Leader>dn', dap.step_over, { desc = "Step over (next line)" })
        vim.keymap.set('n', '<Leader>di', dap.step_into, { desc = "Step into" })
        vim.keymap.set('n', '<Leader>do', dap.step_out, { desc = "Step out" })
        vim.keymap.set('n', '<Leader>dr', dap.repl.toggle, { desc = "Toggle debug console" })
        vim.keymap.set('n', '<Leader>dq', dap.terminate, { desc = "Stop debugging" })
    end
}
