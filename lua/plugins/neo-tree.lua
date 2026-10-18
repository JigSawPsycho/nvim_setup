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
	{ "<C-m>", "<cmd>Neotree reveal left<cr>" }
    },
    opts = {}
}
