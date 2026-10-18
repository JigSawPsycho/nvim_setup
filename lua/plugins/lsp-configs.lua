return {
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
            { "mason-org/mason.nvim", opts = {} },
            "neovim/nvim-lspconfig",
        },
        config = function()
            -- csharpls-extended needs the metadata-uris feature to open decompiled
            -- sources. csharp-ls looks for the .sln/.slnx from its cwd, so start it
            -- in the root directory like nvim-lspconfig's default cmd does.
            vim.lsp.config("csharp_ls", {
                cmd = function(dispatchers, config)
                    return vim.lsp.rpc.start({ "csharp-ls", "--features", "metadata-uris" }, dispatchers, {
                        cwd = config.cmd_cwd or config.root_dir,
                        env = config.cmd_env,
                        detached = config.detached,
                    })
                end,
            })

            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    vim.keymap.set("n", "<leader>ren", vim.lsp.buf.rename, { buffer = args.buf })
                end
            })

            -- Installs these servers and enables every server installed through Mason.
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "csharp_ls", "bashls" }
            })
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
