vim.g.mapleader = " "
vim.cmd("set shiftwidth=4")
vim.cmd("set tabstop=4")
vim.cmd("set expandtab")
vim.cmd("set clipboard+=unnamedplus")
vim.cmd("set relativenumber")
vim.fn.setenv("NVIM_LISTEN_ADDRESS", "/tmp/nvimsocket")

vim.keymap.set("i", "<C-w>", "<Esc>")
