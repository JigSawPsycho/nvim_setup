return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text"
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

        dap.adapters.unity = {
            type = 'executable',
            command = '/opt/mono/bin/mono',
            args = {'/home/mikeevans/vscode-unity-debug/extension/bin/UnityDebug.exe'}
        }

        dap.configurations.cs = {
            {
                type = 'unity',
                request = 'attach',
                name = 'Unity Editor',
                path = "Library/EditorInstance.json",
            }
        }

        vim.keymap.set('n', '<Leader>dt', dap.toggle_breakpoint)
        vim.keymap.set('n', '<Leader>dc', dap.continue)
    end
}
