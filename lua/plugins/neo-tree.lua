return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
	"nvim-lua/plenary.nvim",
	"nvim-tree/nvim-web-devicons",
	"MunifTanjim/nui.nvim",
    },
    lazy = false,
    keys = {
	{ "<C-m>", "<cmd>Neotree reveal left<cr>", desc = "Reveal file in tree" }
    },
    opts = {},
    config = function(_, opts)
        require("neo-tree").setup(opts)
        local file_tree_layout = require("file_tree_layout")
        file_tree_layout.keep_file_tree_at_far_left()
        file_tree_layout.keep_sidebar_widths_when_file_tree_closes()
    end,
}
