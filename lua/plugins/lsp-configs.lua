return {
    {
        "williamboman/mason.nvim",
        config = function()
            require('mason').setup()
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require('mason-lspconfig').setup({
                ensure_installed = { "lua_ls", "csharp_ls", "bashls" }
            })
        end
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            local lspconfig = require("lspconfig")
            lspconfig.lua_ls.setup{}
            lspconfig.bashls.setup {
                cmd = { 'bash-language-server', 'start' },
                filetypes = { 'bash', 'sh' }
            }
            lspconfig.csharp_ls.setup{
                cmd = { "csharp-ls" },
                filetypes = { "cs" },
                init_options = { AutomaticWorkspaceInit = true },
                on_attach = function()
                    vim.keymap.set("n", "<leader>ren", vim.lsp.buf.rename, {})
                end
            }
        end
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
