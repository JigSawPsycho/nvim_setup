return {
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
            {
                "mason-org/mason.nvim",
                opts = {
                    -- The extra registry ships the same Roslyn build as VS Code's C#
                    -- extension. The nuget one in the main registry is too old for roslyn.nvim.
                    registries = {
                        "github:mason-org/mason-registry",
                        "github:Crashdummyy/mason-registry",
                    },
                },
            },
            "neovim/nvim-lspconfig",
        },
        config = function()
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    vim.keymap.set("n", "<leader>ren", vim.lsp.buf.rename, { buffer = args.buf, desc = "Rename symbol" })
                end
            })

            -- Installs these servers and enables every server installed through Mason.
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "bashls" },
                -- roslyn.nvim handles C#. Skip other C# servers in case one is installed through Mason.
                automatic_enable = { exclude = { "csharp_ls", "roslyn_ls" } },
            })

            -- mason-lspconfig only installs servers nvim-lspconfig knows, so install
            -- Roslyn for roslyn.nvim here. Skipped when headless, like ensure_installed,
            -- so scripted runs don't exit partway through the download.
            if #vim.api.nvim_list_uis() > 0 then
                local registry = require("mason-registry")
                registry.refresh(vim.schedule_wrap(function()
                    local ok, roslyn = pcall(registry.get_package, "roslyn")
                    if not ok then
                        vim.notify("Mason package 'roslyn' not found; C# LSP is unavailable", vim.log.levels.WARN)
                    elseif not roslyn:is_installed() and not roslyn:is_installing() then
                        roslyn:install()
                    end
                end))
            end
        end
    },
    {
        -- Starts the Roslyn language server for C# files.
        "seblyng/roslyn.nvim",
        opts = {},
    },
    {
        "ray-x/lsp_signature.nvim",
        event = "InsertEnter",
        opts = {
            bind = true,
            handler_opts = {
                border = "rounded"
            }
        }
    }
}
