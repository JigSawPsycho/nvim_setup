return {
    {
	'nvim-telescope/telescope.nvim', version = '*',
	dependencies = {
	    'nvim-lua/plenary.nvim',
	    "jonarrien/telescope-cmdline.nvim",
	},
	config = function()
	    local builtin = require("telescope.builtin")
	    vim.keymap.set("n", "<leader>ref", builtin.lsp_references, { desc = "References" })
	    vim.keymap.set("n", "<leader>inc", builtin.lsp_incoming_calls, { desc = "Incoming calls" })
	    vim.keymap.set("n", "<leader>out", builtin.lsp_outgoing_calls, { desc = "Outgoing calls" })
	    vim.keymap.set("n", "<leader>imp", builtin.lsp_implementations, { desc = "Implementations" })
	    vim.keymap.set("n", "<leader>typ", builtin.lsp_type_definitions, { desc = "Type definitions" })
	    vim.keymap.set("n", "<leader>def", builtin.lsp_definitions, { desc = "Definitions" })
	    vim.keymap.set("n", "<leader>old", builtin.oldfiles, { desc = "Recent files" })
	    vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = "Find files" })
	    vim.keymap.set('n', '<C-f>', builtin.live_grep, { desc = "Search in files" })
	    vim.keymap.set('n', '<leader><leader>', ':Telescope cmdline<CR>', { desc = "Command line" })
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
	"agoodshort/telescope-git-submodules.nvim",
	dependencies = {
	    "akinsho/toggleterm.nvim",
	},
	config = function()
	    require("telescope").load_extension("git_submodules")
	end
    }
}
