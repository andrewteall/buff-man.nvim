local M = {}

---Determines if a specified buffer is a scratch buffer.
---@param buf integer The buffer to check.
---@return boolean boolean Whether or not the buffer is a scratch buffer.
function M.is_scratch(buf)
    if
        type(buf) == "number"
        and vim.api.nvim_buf_is_valid(buf)
        and vim.api.nvim_get_option_value("buftype", { buf = buf }) == "nofile"
        and vim.api.nvim_get_option_value("bufhidden", { buf = buf }) == "hide"
        and vim.api.nvim_get_option_value("swapfile", { buf = buf }) == false
    then
        return true
    else
        return false
    end
end

---Gets the value of the specified option for a buffer.
---@param buf integer|nil The buffer to check.
---@param buffer_option string The option to be requested.
---@return any any The value of the option requested.
function M.get_option(buf, buffer_option)
    if type(buf) == "number" and vim.api.nvim_buf_is_valid(buf) then
        return vim.api.nvim_get_option_value(buffer_option, { buf = buf })
    else
        return nil
    end
end

---Returns the relative path of the specified buffer from the current working
---directory.
---@param buf integer The buffer to find the relatve path to.
---@return string relative_path The relative path of the buffer.
---@see vim.fn.fnamemodify
function M.get_relative_path(buf)
    local relative_path = ""
    if type(buf) == "number" and vim.api.nvim_buf_is_valid(buf) then
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if buf_name and buf_name ~= "" then
            relative_path = vim.fn.fnamemodify(buf_name, ":~:.")
        end
    end
    return relative_path
end

---Returns the name of the specified buffer.
---@param buf integer|nil The buffer to get the name of. Default: Current Buffer
---@param format string|nil The format of the buffer name. Default: relative
---@return string formatted_buffer_name The buffer name in the specified format.
function M.get_name(buf, format)
    buf = buf or 0
    format = format or "relative"
    local formatted_buf_name = ""
    local buf_name = vim.api.nvim_buf_get_name(buf)
    if buf_name ~= "" then
        if format == "full" then
            formatted_buf_name = buf_name
        elseif format == "short" then
            formatted_buf_name = vim.fn.fnamemodify(buf_name, ":p:t")
        elseif M.get_option(buf, "buftype") == "terminal" then
            formatted_buf_name = vim.fn.fnamemodify(buf_name, ":h")
        else
            formatted_buf_name = vim.fn.fnamemodify(buf_name, ":~:.")
        end
    elseif M.get_option(buf, "buftype") == "quickfix" then
        formatted_buf_name = "[Quickfix List]"
    elseif M.is_scratch(buf) then
        formatted_buf_name = "[Scratch]"
    else
        formatted_buf_name = "[No Name]"
    end
    return formatted_buf_name
end

---Checks to see if a string is a valid buffer name.
---@param buf_name string The string to check to be used as a buffer name.
---@return boolean boolean Returns true if the name is valid for a buffer.
function M.is_valid_name(buf_name)
    if not buf_name or buf_name == "" then
        vim.notify("ERROR: Buffer name cannot be blank", vim.log.levels.ERROR)
    elseif M.exists(buf_name) then
        vim.notify("ERROR: Buffer already exists ", vim.log.levels.ERROR)
    else
        return true
    end
    return false
end

---Returns the string of flags for a specified buffer.
---@param buf integer The buffer to check the flags.
---@param win integer The window of the buffer to get the alternate buffer.
---@return string buf_flags The string of flags for the specified buffer.
function M.get_flags(buf, win)
    local buf_flags = ""
    if not M.get_option(buf, "buflisted") then
        buf_flags = buf_flags .. "u"
    else
        buf_flags = buf_flags .. " "
    end
    -- buf_flags = buf_flags .. ((M.get_option(buf,"buflisted") and " ") or "u")

    if M.get_alternate(win) == buf then
        buf_flags = buf_flags .. "#"
    elseif vim.api.nvim_win_get_buf(win) == buf then
        buf_flags = buf_flags .. "%"
    else
        buf_flags = buf_flags .. " "
    end
    -- buf_flags = buf_flags .. ((((M.get_alternate(win) == buf) and "#") or (vim.api.nvim_win_get_buf(win) == buf) and "%") or " ")

    if vim.fn.bufwinnr(buf) ~= -1 then
        buf_flags = buf_flags .. "a"
    elseif vim.api.nvim_buf_is_loaded(buf) and vim.fn.bufwinnr(buf) == -1 then
        buf_flags = buf_flags .. "h"
    else
        buf_flags = buf_flags .. " "
    end
    -- buf_flags = buf_flags .. ((((vim.fn.bufwinnr(buf) ~= -1) and "a") or (vim.api.nvim_buf_is_loaded(buf) and vim.fn.bufwinnr(buf) == -1) and "h") or " ")

    if M.get_option(buf, "buftype") == "terminal" then
        if vim.api.nvim_buf_get_var(buf, "terminal_job_id") == 0 then
            buf_flags = buf_flags .. "F"
        elseif vim.api.nvim_buf_get_var(buf, "terminal_job_id") then
            buf_flags = buf_flags .. "R"
        else
            buf_flags = buf_flags .. "?"
        end
    elseif not M.get_option(buf, "modifiable") then
        buf_flags = buf_flags .. "-"
    elseif M.get_option(buf, "readonly") then
        buf_flags = buf_flags .. "="
    else
        buf_flags = buf_flags .. " "
    end

    if M.get_option(buf, "modified") then
        buf_flags = buf_flags .. "+"
    else
        buf_flags = buf_flags .. " "
    end
    -- buf_flags = buf_flags .. ((M.get_option(buf,"modified") and "+") or " ")
    return buf_flags
end

---Highlights the specified range in the specified buffer with the specified
---highlight.
---@param buf integer The buffer to add the highlight.
---@param hl_line integer The line to highlight.
---@param hl_start integer The starting position of the highlight.
---@param hl_end integer The ending position of the highlight.
---@param hl_name string The name for the highlight.
---@param hl table The actual highlight config.
---@see vim.api.nvim_set_hl
---@see vim.api.nvim_buf_add_highlight
function M.highlight_range(buf, hl_line, hl_start, hl_end, hl_name, hl)
    vim.api.nvim_set_hl(0, hl_name, hl)
    vim.api.nvim_buf_add_highlight(buf, -1, hl_name, hl_line, hl_start, hl_end)
end

---Highlights the specified line in the specified buffer with the specified
---highlight.
---@param buf integer The buffer to add the highlight.
---@param hl_line integer The line to highlight.
---@param hl_name string The name for the highlight.
---@param hl table The actual highlight config.
---@see vim.api.nvim_set_hl
---@see vim.api.nvim_buf_add_highlight
function M.highlight_line(buf, hl_line, hl_name, hl)
    local line = vim.api.nvim_buf_get_lines(buf, hl_line, hl_line + 1, true)[1]
    M.highlight_range(buf, hl_line, 0, string.len(line), hl_name, hl)
end

---Gets the icon and color for the specifed buffer.
---@param buf integer|nil The buffer to retrieve the icon for. Default: 0
---@return string icon The icon for the buffer.
---@return string color The color for the icon in cterm format.
---@return string colorHex The color for the icon in hexidecimal format.
function M.get_icon_color(buf)
    buf = buf or 0
    local devicons = require("nvim-web-devicons")
    local ft = M.get_option(buf, "filetype")
    local icon, color = devicons.get_icon_cterm_color_by_filetype(ft, {})
    local _, colorHex = devicons.get_icon_color_by_filetype(ft, {})
    if not icon then
        local buf_name = vim.api.nvim_buf_get_name(buf)
        -- local ext = string.match(buf_name, "[^%.]*$")
        local ext = vim.fn.fnamemodify(buf_name, ":e")
        icon, color = devicons.get_icon_cterm_color(buf_name, ext, {})
        _, colorHex = devicons.get_icon_color(buf_name, ext, {})
    end
    if not icon then
        if M.get_option(buf, "buftype") == "terminal" then
            icon = ""
        elseif M.get_option(buf, "buftype") == "quickfix" then
            icon = ""
        elseif M.is_scratch(buf) then
            icon = "󱇗"
        elseif M.get_option(buf, "filetype") == "buff-man" then
            icon = "󱅝" -- "󰘔" ""
        else
            icon = "" -- Default Icon if no icon is found.
        end
    end
    return icon, color, colorHex
end

---Ensures the the specified buffer is loaded.
---@param buf integer The buffer to ensure is loaded.
function M.ensure_loaded(buf)
    if vim.api.nvim_buf_is_valid(buf) and not vim.api.nvim_buf_is_loaded(buf) then
        vim.fn.bufload(buf)
    end
end

---Returns the list of all buffers with the specified ordering.
---@param ordering string|nil The ordering of the buffers. Default: "inorder"
---@return table buffer_num_list The table containing the list of buffers.
function M.list(ordering)
    local buffer_num_list = {}
    if ordering == "mru" then
        local bufs_str = vim.api.nvim_command_output("ls! t")
        for line in string.gmatch(bufs_str, "([^\n]+)") do
            local buf_num = tonumber(string.match(line, "%d+"))
            table.insert(buffer_num_list, buf_num)
        end
    else
        buffer_num_list = vim.api.nvim_list_bufs()
    end
    return buffer_num_list
end

---Returns whether or not the specified buffer name exists.
---@param buf_name string The name of the buffer to look for.
---@return boolean boolean Whether or not the buffer exists.
function M.exists(buf_name)
    if vim.fn.bufnr(buf_name) ~= -1 then
        return true
    end
    return false
end

---Rename the specified buffer to the specified new name.
---@param buf integer The buffer to rename.
---@param buf_new_name string The new name of the buffer.
---@return boolean boolean Returns true is the rename is successful.
function M.rename(buf, buf_new_name)
    if M.is_valid_name(buf_new_name) then
        vim.api.nvim_buf_set_name(buf, buf_new_name)
        return true
    end
    return false
end

---Converts the specified buffer to a terminal and runs specified commands if
---supplied.
---@param buf integer The buffer to convert to a terminal.
---@param buf_name string The name of the terminal and commands if desired.
---@usage convert_to_term(1, "term | ls -alh")
local function convert_to_term(buf, buf_name)
    vim.api.nvim_buf_call(buf, function()
        local term_id = vim.fn.termopen("bash")
        if string.sub(buf_name, 1, 11) == "terminal | " then
            vim.api.nvim_chan_send(term_id, string.sub(buf_name, 12, -1) .. "\n")
        elseif string.sub(buf_name, 1, 7) == "term | " then
            vim.api.nvim_chan_send(term_id, string.sub(buf_name, 8, -1) .. "\n")
        end
    end)
end

---Creates a new buffer with the specified name.
---@param buf_new_name string The name of the new buffer.
---@return boolean boolean Returns true if the operation is successful.
function M.new(buf_new_name)
    local new_buf = vim.api.nvim_create_buf(true, false)
    if new_buf == 0 and not vim.api.nvim_buf_is_valid(new_buf) then
        vim.notify("ERROR: Could not create buffer", vim.log.levels.ERROR)
        return false
    end
    if not M.rename(new_buf, buf_new_name) then
        vim.api.nvim_buf_delete(new_buf, {})
        return false
    else
        vim.api.nvim_buf_call(new_buf, function()
            vim.cmd("filetype detect")
        end)
    end
    if
        buf_new_name == "terminal"
        or buf_new_name == "term"
        or string.sub(buf_new_name, 1, 11) == "terminal | "
        or string.sub(buf_new_name, 1, 7) == "term | "
    then
        convert_to_term(new_buf, buf_new_name)
    end
    return true
end

---Copies the specified buffer to a new buffer with the specified name.
---@param buf integer The buffer to copy.
---@param buf_new_name string The name of the new buffer.
function M.copy(buf, buf_new_name)
    if M.is_valid_name(buf_new_name) then
        local new_buf = vim.api.nvim_create_buf(true, false)
        if new_buf ~= 0 and vim.api.nvim_buf_is_valid(new_buf) then
            vim.api.nvim_buf_set_name(new_buf, buf_new_name)
            local contents = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, contents)
            local filetype = M.get_option(buf, "filetype")
            vim.api.nvim_set_option_value("filetype", filetype, { buf = new_buf })
        else
            vim.notify("ERROR: Could not create buffer", vim.log.levels.ERROR)
        end
    end
end

---Opens the specified buffer in the specified window.
---@param buf integer The buffer to open.
---@param win integer The window to open the buffer in.
---@param opts table
function M.open(buf, win, opts)
    local invert = ""
    if opts.invert then
        invert = "!"
    end
    if buf and vim.api.nvim_buf_is_valid(buf) then
        if opts.split == "v" then
            vim.api.nvim_win_call(win, function()
                vim.cmd("vsplit" .. invert)
                vim.cmd("b " .. buf)
            end)
        elseif opts.split == "h" then
            vim.api.nvim_win_call(win, function()
                vim.cmd("split" .. invert)
                vim.cmd("b " .. buf)
            end)
        else
            vim.api.nvim_win_set_buf(win, buf)
        end
    else
        vim.notify("ERROR: Cannot open buffer", vim.log.levels.ERROR)
    end
end

---Deletes the specified buffer.
---@param buf integer The buffer to be deleted.
---@param force boolean|nil Whether or not to force deletion. Default: false
function M.delete(buf, force)
    force = force or false
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        vim.notify("ERROR: Invalid buffer", vim.log.levels.ERROR)
        return
    end
    local modified = vim.api.nvim_get_option_value("modified", { buf = buf })
    if modified and not force then
        vim.notify("ERROR: Buffer is modified, use force to delete", vim.log.levels.ERROR)
        return
    end
    if M.get_option(buf, "buftype") == "terminal" then
        force = true
    end
    local windows = vim.fn.win_findbuf(buf)
    if windows ~= -1 then
        for _, win in ipairs(windows) do
            vim.api.nvim_win_call(win, function()
                vim.cmd(":bnext")
            end)
        end
    end
    vim.api.nvim_buf_delete(buf, { force = force })
end

---Writes the specified buffer to disk.
---@param buf integer The buffer to write to disk.
---@return boolean boolean Returns true is the operation is sucessful.
function M.write(buf)
    if not buf and not vim.api.nvim_buf_is_valid(buf) then
        vim.notify("ERROR: Cannot write buffer", vim.log.levels.ERROR)
        return false
    end
    vim.api.nvim_buf_call(buf, function()
        vim.cmd(":write")
    end)
    return true
end

---Sets the specified alternate buffer for a specified window.
---@param buf integer The buffer to set as alternate.
---@param win integer The windows in which to set the alternate buffer.
function M.set_alternate(buf, win)
    if buf and vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_win_call(win, function()
            vim.cmd(":b" .. buf)
            vim.cmd(":b#")
        end)
    else
        vim.notify("ERROR: Cannot set alternate buffer", vim.log.levels.ERROR)
    end
end

---Returns the alternate buffer for a specified window.
---@param win integer The window to get the alternate buffer.
---@return integer The alternate buffer for the specified window.
function M.get_alternate(win)
    local alt_buf_num = vim.api.nvim_win_call(win, function()
        return vim.fn.bufnr("#")
    end)
    return alt_buf_num
end

---Returns the cursor position of the specifed buffer.
---@deprecated
---@param buf integer The buffer used to find the cursor position.
---@return table cur_pos The x and y cursor position in the specified buffer.
function M.get_cursor_pos(buf)
    local default_window_config = {
        relative = "win",
        style = "minimal",
        width = 20,
        height = 20,
        row = 1,
        col = 1,
        hide = true,
        noautocmd = true,
        border = "none",
        focusable = false,
    }
    local check_win = vim.api.nvim_open_win(buf, false, default_window_config)
    vim.api.nvim_win_set_buf(check_win, buf)
    local cur_pos = vim.api.nvim_win_get_cursor(check_win)
    vim.api.nvim_win_close(check_win, false)
    return cur_pos
end

---Sets the contents of a given buffer.
---buf - The buffer to set the contents
---text - The text of the contents
---start_line - The starting line to replace
---end_line - The ending line to replace
---@param buf number The buffer to set the text.
---@param text table The table containing the lines of text. 1 line per index.
---@param start_line number|nil The starting line to replace text. Default: 0
---@param end_line number|nil The ending line to replace text to. Default: -1
function M.set_text(buf, text, start_line, end_line)
    start_line = start_line or 0
    end_line = end_line or -1
    local buf_mod = M.get_option(buf, "modifiable")
    local buf_win_id = vim.api.nvim_call_function("bufwinid", { buf })
    local cursor_pos = { 1, 1 }
    if buf_win_id ~= -1 then
        cursor_pos = vim.api.nvim_win_get_cursor(buf_win_id)
    end
    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
    -- vim.api.nvim_buf_set_lines(buf, start_line, end_line, true, {})
    vim.api.nvim_buf_set_lines(buf, start_line, end_line, true, text)
    -- Set the cursor position to the line we were just on.
    if buf_win_id ~= -1 then
        if cursor_pos[1] > vim.api.nvim_buf_line_count(buf) then
            cursor_pos = { #vim.api.nvim_buf_get_lines(buf, 0, -1, true), 1 }
        end
        vim.api.nvim_win_set_cursor(buf_win_id, cursor_pos)
    end
    vim.api.nvim_set_option_value("modifiable", buf_mod, { buf = buf })
end

return M
