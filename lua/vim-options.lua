vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.clipboard:append("unnamedplus")
vim.opt.relativenumber = true
vim.env.NVIM_LISTEN_ADDRESS = "/tmp/nvimsocket"

vim.keymap.set("i", "<C-w>", "<Esc>")
