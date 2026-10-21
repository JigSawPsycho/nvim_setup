return {
    "saghen/blink.cmp",
    -- A release tag downloads the prebuilt fuzzy matcher, so no Rust toolchain is needed.
    version = "1.*",
    -- Load at startup so its LSP capabilities are set before any server starts.
    lazy = false,
    opts = {
        -- Enter accepts the selected item. Up/Down or C-n/C-p move through the list.
        keymap = { preset = "enter" },
        completion = {
            documentation = { auto_show = true, auto_show_delay_ms = 200 },
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
    },
}
