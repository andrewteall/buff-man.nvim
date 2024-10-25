vim.api.nvim_create_user_command("BuffManOpen", function()
    require("buff-man").open_buffer_manager()
end, { desc = "Open the Buffer Manager." })

vim.api.nvim_create_user_command("BuffManBufferOpen", function()
    require("buff-man.config").set_mode("buffer")
    require("buff-man").open_buffer_manager()
end, { desc = "Open the Buffer Manager." })

vim.api.nvim_create_user_command("BuffManMarkOpen", function()
    require("buff-man.config").set_mode("marks")
    require("buff-man").open_buffer_manager()
end, { desc = "Open the Buffer Manager." })

vim.api.nvim_create_user_command("BuffManMarkNext", function()
    local mark = require("buff-man.mark")
    vim.api.nvim_win_set_buf(0, mark.get_next(vim.api.nvim_get_current_buf()))
end, { desc = "Move to the next Bookmark in Buffer Manager." })

vim.api.nvim_create_user_command("BuffManMarkPrev", function()
    local mark = require("buff-man.mark")
    vim.api.nvim_win_set_buf(0, mark.get_prev(vim.api.nvim_get_current_buf()))
end, { desc = "Move to the previous Bookmark in Buffer Manager." })

vim.api.nvim_create_user_command("BuffManMarkToggle", function()
    local mark = require("buff-man.mark")
    mark.toggle(vim.api.nvim_get_current_buf())
end, { desc = "Toggle a Buffer Manager Bookmark on or off." })
