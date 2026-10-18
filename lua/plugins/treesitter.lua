return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").install({ "lua", "c_sharp" })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "lua", "cs" },
            callback = function(args)
                -- The parser may still be installing, so don't error without it.
                if not pcall(vim.treesitter.start, args.buf) then
                    return
                end
                -- Only languages with an indents query (c_sharp has none) can use
                -- treesitter indentation; others keep their indent/*.vim.
                local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
                if vim.treesitter.query.get(lang, "indents") then
                    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end
        })
    end
}
