-- AI completion from Claude or a local model. Off for now: set `enabled = true` to try it.
-- Claude reads the API key from $ANTHROPIC_API_KEY. The local option expects Ollama
-- running qwen2.5-coder:7b. `:Minuet change_provider` switches the ghost text between
-- them; next-edit prediction always uses Claude.
return {
    "milanglacier/minuet-ai.nvim",
    enabled = false,
    -- Ghost text turns on per buffer when its filetype is set, so load before any file opens.
    lazy = false,
    opts = {
        provider = "claude",
        -- Automatic ghost text only in real files, so typing in pickers, prompts and dotenv
        -- files isn't sent. Pressing a minuet key still sends the current buffer.
        enable_predicates = {
            function()
                local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
                return vim.bo.buftype == "" and name ~= ".env" and not vim.startswith(name, ".env.")
            end,
        },
        provider_options = {
            -- Shares the top-level settings (n_completions, context_window, timeouts) with the
            -- Claude provider. If a local model is slow, lower `n_completions` and `context_window`.
            openai_fim_compatible = {
                -- Ollama needs no key, but minuet requires the named env var to be set,
                -- so name one that always is.
                api_key = "TERM",
                name = "Ollama",
                end_point = "http://localhost:11434/v1/completions",
                model = "qwen2.5-coder:7b",
                optional = { max_tokens = 56, top_p = 0.9 },
            },
        },
        -- Ghost text at the cursor while typing. Hidden while the completion menu is open.
        virtualtext = {
            auto_trigger_ft = { "*" },
            keymap = {
                accept = "<A-A>",
                accept_line = "<A-a>",
                accept_n_lines = "<A-z>",
                prev = "<A-p>",
                next = "<A-n>",
                dismiss = "<A-e>",
            },
        },
        -- Next-edit prediction across the file. Experimental, so it only runs on request.
        duet = {
            provider = "claude",
        },
    },
    keys = {
        { "<leader>mp", "<cmd>Minuet duet predict<cr>", desc = "Predict next edit" },
        { "<leader>ma", "<cmd>Minuet duet apply<cr>", desc = "Apply predicted edit" },
        { "<leader>md", "<cmd>Minuet duet dismiss<cr>", desc = "Dismiss predicted edit" },
    },
}
