return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        -- Names for key prefixes, shown in the popup instead of "+N keymaps".
        spec = {
            { "<leader>c", group = "Code (Trouble)" },
            { "<leader>d", group = "Debug" },
            { "<leader>x", group = "Diagnostics (Trouble)" },
        },
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Keymaps for this buffer",
        },
    },
}
