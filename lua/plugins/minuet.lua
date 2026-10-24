-- AI completion from local models served by Ollama on localhost:11434. Nothing is sent
-- off this machine. Together the two models take about 14 GB, so both stay loaded on a
-- 16 GB GPU and Ollama never has to swap them.
local ollama_end_point = "http://localhost:11434/v1"
-- Ghost text runs on every typing pause, so it uses the smaller model: about twice as fast
-- as 14b with similar accuracy.
local ghost_text_model = "qwen2.5-coder:7b"
-- Next-edit prediction only runs on request, so it can afford the bigger model.
local next_edit_model = "qwen2.5-coder:14b"

-- Ollama ignores the key, but minuet refuses to send a request without one.
local function ollama_api_key()
    return "ollama"
end

return {
    "milanglacier/minuet-ai.nvim",
    -- Without Ollama every typing pause would show a failed-request error, so skip
    -- machines that don't have it.
    cond = vim.fn.executable("ollama") == 1,
    -- Ghost text turns on per buffer when its filetype is set, so load before any file opens.
    lazy = false,
    opts = {
        provider = "openai_fim_compatible",
        -- One suggestion per pause and a small context keep a local model responsive.
        n_completions = 1,
        context_window = 2048,
        -- Ask after a short pause in typing. The default 400ms wait is longer than the model
        -- takes to answer.
        debounce = 150,
        -- No minimum gap between requests. With one, a pause that comes too soon after the
        -- last request gets no suggestion at all, and minuet doesn't retry.
        throttle = 0,
        -- Automatic ghost text only in real files, so typing in pickers, prompts and dotenv
        -- files isn't sent. Pressing a minuet key still sends the current buffer.
        enable_predicates = {
            function()
                local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
                return vim.bo.buftype == "" and name ~= ".env" and not vim.startswith(name, ".env.")
            end,
        },
        provider_options = {
            openai_fim_compatible = {
                api_key = ollama_api_key,
                name = "Ollama",
                -- Fill-in-the-middle endpoint: the model sees code before and after the cursor.
                end_point = ollama_end_point .. "/completions",
                model = ghost_text_model,
                optional = {
                    max_tokens = 56,
                    top_p = 0.9,
                    -- End at the first blank line. Otherwise the model keeps writing extra
                    -- methods, and each extra word adds to the wait.
                    stop = { "\n\n" },
                },
            },
        },
        -- Ghost text at the cursor while typing.
        virtualtext = {
            auto_trigger_ft = { "*" },
            -- blink's menu is open for most of the time you're typing, and by default minuet
            -- doesn't even ask for a suggestion while it is.
            show_on_completion_menu = true,
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
            provider = "openai_compatible",
            provider_options = {
                openai_compatible = {
                    api_key = ollama_api_key,
                    name = "Ollama",
                    -- Duet sends a rewrite request, which needs the chat endpoint.
                    end_point = ollama_end_point .. "/chat/completions",
                    model = next_edit_model,
                },
            },
        },
    },
    keys = {
        { "<leader>mp", "<cmd>Minuet duet predict<cr>", desc = "Predict next edit" },
        { "<leader>ma", "<cmd>Minuet duet apply<cr>", desc = "Apply predicted edit" },
        { "<leader>md", "<cmd>Minuet duet dismiss<cr>", desc = "Dismiss predicted edit" },
    },
}
