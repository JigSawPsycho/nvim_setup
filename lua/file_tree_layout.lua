-- Keeps the neo-tree file tree at the far left of the screen. Other plugins (such as dap-ui)
-- open their sidebars at the far left too, which pushes the tree into the middle.
--
-- When that happens the tree is closed and reopened on the left, the same as doing it by hand.
-- Neovim and neo-tree then size every window themselves. Moving the tree and putting the old
-- widths back was tried first, but the old widths often don't fit the new layout and it
-- crushed other windows.
--
-- Lua needs a local function defined before it's used, so the helpers come first and the
-- two entry points (keep_file_tree_at_far_left and keep_sidebar_widths_when_file_tree_closes)
-- are at the bottom.
local M = {}

-- Only the tree opened on the left counts. A tree opened on the right, top or bottom, or in
-- the current window, stays where the user put it.
local function is_left_file_tree(buf)
    return vim.b[buf].neo_tree_position == "left"
end

local function find_left_file_tree_window()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if is_left_file_tree(vim.api.nvim_win_get_buf(win)) then return win end
    end
    return nil
end

local function reopen_file_tree_at_far_left(tree)
    local source = vim.b[vim.api.nvim_win_get_buf(tree)].neo_tree_source
    -- "show" opens the tree without moving the cursor into it, so only use "focus" if the
    -- cursor was already there.
    local action = vim.api.nvim_get_current_win() == tree and "focus" or "show"
    local neo_tree = require("neo-tree.command")

    -- Closing through neo-tree, not nvim_win_close, so it saves the cursor line in the tree.
    neo_tree.execute({ action = "close", source = source, position = "left" })
    -- The close above fires WinClosed, which queues the sidebar width restore
    -- (restore_sidebar_widths_after_tree_closes). This reopen is queued after it, so the
    -- widths are back before the tree reopens, the same as a user closing and reopening it.
    vim.schedule(function()
        neo_tree.execute({ action = action, source = source, position = "left" })
    end)
end

local function reopen_file_tree_if_pushed_from_far_left()
    local tree = find_left_file_tree_window()
    if not tree then return end
    -- Reopening the tree resizes windows and runs this again; returning here stops the loop.
    if vim.api.nvim_win_get_position(tree)[2] == 0 then return end

    reopen_file_tree_at_far_left(tree)
end

local function non_floating_windows()
    return vim.tbl_filter(function(win)
        return vim.api.nvim_win_get_config(win).relative == ""
    end, vim.api.nvim_tabpage_list_wins(0))
end

-- When the tree is the leftmost window and closes, Neovim gives its space to the window
-- directly to its right, which is often a sidebar such as dap-ui's. Sidebars mark themselves
-- with 'winfixwidth', so putting them back to their old width hands the space to the code
-- windows instead.
local function restore_sidebar_widths_after_tree_closes(tree)
    local sidebars = vim.tbl_filter(function(win)
        return win ~= tree and vim.wo[win].winfixwidth
    end, non_floating_windows())
    local widths = {}
    for _, win in ipairs(sidebars) do
        widths[win] = vim.api.nvim_win_get_width(win)
    end

    -- The layout can't be changed while a window is closing, so wait until it has closed.
    vim.schedule(function()
        local open_sidebars = vim.tbl_filter(vim.api.nvim_win_is_valid, sidebars)
        -- Setting a width takes space from the window to the right, so going left to right
        -- means each sidebar only changes windows that haven't been restored yet.
        table.sort(open_sidebars, function(a, b)
            return vim.api.nvim_win_get_position(a)[2] < vim.api.nvim_win_get_position(b)[2]
        end)
        for _, win in ipairs(open_sidebars) do
            vim.api.nvim_win_set_width(win, widths[win])
        end
    end)
end

function M.keep_file_tree_at_far_left()
    vim.api.nvim_create_autocmd({ "WinNew", "WinResized" }, {
        group = vim.api.nvim_create_augroup("KeepFileTreeAtFarLeft", { clear = true }),
        desc = "Keep the file tree at the far left",
        -- Wait until the plugin that opened the window has finished building its layout.
        callback = function() vim.schedule(reopen_file_tree_if_pushed_from_far_left) end,
    })
end

function M.keep_sidebar_widths_when_file_tree_closes()
    vim.api.nvim_create_autocmd("WinClosed", {
        group = vim.api.nvim_create_augroup("KeepSidebarWidthsWhenFileTreeCloses", { clear = true }),
        desc = "Keep sidebar widths when the file tree closes",
        callback = function(event)
            if not is_left_file_tree(event.buf) then return end
            local closed_window = tonumber(event.match)
            restore_sidebar_widths_after_tree_closes(closed_window)
        end,
    })
end

return M
