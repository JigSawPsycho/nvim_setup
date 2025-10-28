return {
    {
	'nvim-telescope/telescope.nvim', tag = '0.1.8',
	dependencies = {
	    'nvim-lua/plenary.nvim',
	    "jonarrien/telescope-cmdline.nvim",
	},
	config = function()
	    local builtin = require("telescope.builtin")
	    vim.keymap.set("n", "<leader>ref", builtin.lsp_references, {})
	    vim.keymap.set("n", "<leader>inc", builtin.lsp_incoming_calls, {})
	    vim.keymap.set("n", "<leader>out", builtin.lsp_outgoing_calls, {})
	    vim.keymap.set("n", "<leader>imp", builtin.lsp_implementations, {})
	    vim.keymap.set("n", "<leader>typ", builtin.lsp_type_definitions, {})
	    vim.keymap.set("n", "<leader>old", builtin.oldfiles, {})
	    vim.keymap.set('n', '<C-p>', builtin.find_files, {})
	    vim.keymap.set('n', '<C-f>', builtin.live_grep, {})
	    vim.keymap.set('n', '<leader><leader>', ':Telescope cmdline<CR>')
	    --    vim.keymap.set('n', '<C-d>', function()
	    --	builtin.lsp_definitions({jump_type = "split"})
	    --end)
	end
    },
    {
	"nvim-telescope/telescope-ui-select.nvim",
	config = function()
	    require("telescope").load_extension("ui-select")
	end
    },
    {
	"Decodetalkers/csharpls-extended-lsp.nvim",
	config = function()
	    local csharpls = require("telescope").load_extension("csharpls_definition")
	    vim.keymap.set("n", "<leader>def", csharpls.csharpls_definition, {})
	end
    },
    {
	"agoodshort/telescope-git-submodules.nvim",
	dependencies = {
	    "akinsho/toggleterm.nvim",
	},
	config = function()
	    require("telescope").load_extension("git_submodules")
	end
    }
}
