local M = {}

local buffer = require("buff-man.buffer")
local config = require("buff-man.config")
local mark = require("buff-man.mark")
local ui = require("buff-man.ui")
local utils = require("buff-man.utils")

---Boolean to track whether the Buffer Manager is open.
---@type boolean
local is_open = false

---Table containing a window
---@type table
local buffer_list_win = {}

---Table containing a window
---@type table
local input_win = {}

---Takes in a table of lines, extracts the buffer, and returns all buffers that
---match the specified option. If invert is true all buffers not matching the
---specified option are returned.
---@param lines table
---@param option string
---@param invert boolean|nil
---@return table
local function match_line_option(lines, option, invert)
    local buf_list = {}
    for line_num, line in ipairs(lines) do
        local handle = tonumber(string.match(line, "%d+"))
        local buf_opt = buffer.get_option(handle, option)
        if utils.xor(buf_opt, invert) then
            buf_list[#buf_list + 1] = line_num - 1
        end
    end
    return buf_list
end

---Returns a table that contains lookups to decode the buffer line format.
---@param buf integer The buffer to build the look up table for.
---@return table format_lookup_table The lookup table
local function get_formatted_lookup_table_for_buffer(buf)
    local buf_flags = buffer.get_flags(buf, buffer_list_win.parent)
    local line_count = vim.api.nvim_buf_line_count(buf)
    local buf_name_format = config.get_runtime_option("buffer_list_name_format")
    local buf_name_width = config.get_buffer_list_value("filename_width")
    local buf_name = buffer.get_name(buf, tostring(buf_name_format))
    local file_type = buffer.get_option(buf, "filetype")
    local is_marked = (mark.find(buf) and "*") or " "
    local icon = (config.get_value("use_icons") and buffer.get_icon_color(buf)) or ""
    local format_lookup_table = {
        ["b"] = string.format("%3d", buf),
        ["f"] = string.format(" %5s", buf_flags),
        ["s"] = " ",
        ["i"] = icon,
        ["n"] = string.format("%-" .. buf_name_width .. "s", buf_name),
        ["l"] = string.format("%5d lines", line_count),
        ["t"] = string.format("%-11s", file_type),
        ["m"] = is_marked,
    }
    setmetatable(format_lookup_table, {
        __index = function()
            return ""
        end,
    })
    return format_lookup_table
end

---Formats a buffer manager line for a given buffer.
---@param buf integer
---@param line_format string
---@return string formatted_line
local function format_buffer_line(buf, line_format)
    buffer.ensure_loaded(buf)
    local format_lookup_table = get_formatted_lookup_table_for_buffer(buf)
    local formatted_line = string.format("%3d", buf)
    for i = 1, #line_format do
        local key = string.sub(line_format, i, i)
        formatted_line = formatted_line .. format_lookup_table[key]
    end
    return formatted_line
end

---Formats and returns the formatted buffer list from a list of buffers.
---@param buf_list table
---@return table
local function format_buffer_list(buf_list)
    local contents = {}
    local line_format = config.get_buffer_list_line_format()
    for _, buf in ipairs(buf_list) do
        if
            vim.api.nvim_buf_is_valid(buf)
            and (
                buffer.get_option(buf, "buflisted")
                or config.get_runtime_option("show_hidden")
                or config.get_mode() == "marks"
            )
        then
            contents[#contents + 1] = format_buffer_line(buf, line_format)
        end
    end
    return contents
end

---Highlight Icons for the Buffer Manager.
---@param buf integer
---@param line_num integer
---@param line string
local function highlight_icons_in_line(buf, line_num, line)
    local idx = 1
    while idx <= #line do
        local byte = string.byte(line, idx)
        local char_size = utils.get_character_size(byte)
        local character = string.sub(line, idx, idx + char_size - 1)
        if utils.is_nerd_font_icon(character) then
            local handle = tonumber(string.match(string.sub(line, 1, string.find(line, '"')), "%d+"))
            local _, color, colorHex = buffer.get_icon_color(handle)
            local start = idx - 1
            local hl = { fg = colorHex, ctermfg = color }
            buffer.highlight_range(buf, line_num - 1, start, start + char_size, "BMIconHL" .. line_num, hl)
        end
        idx = idx + char_size
    end
end

---Highlights buffers to indicate their status.
---@param buf integer The buffer to highlight
local function add_indicator_highlights(buf)
    local contents = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local cur_buf_num = vim.api.nvim_win_get_buf(buffer_list_win.parent)
    local cur_buf_row = ui.find_buffer(cur_buf_num, buf)
    local alt_buf_num = buffer.get_alternate(buffer_list_win.parent)
    local alt_buf_row = ui.find_buffer(alt_buf_num, buf)
    local hl_config = config.get_buffer_list_value("highlights")
    if cur_buf_row then
        buffer.highlight_line(buf, cur_buf_row - 1, "BMCurBufHl", hl_config.cur_buf_hl)
    end
    if alt_buf_row then
        buffer.highlight_line(buf, alt_buf_row - 1, "BMAltBufHl", hl_config.alt_buf_hl)
    end
    for _, line in ipairs(match_line_option(contents, "buflisted", true)) do
        buffer.highlight_line(buf, line, "BMHidBufHl", hl_config.hid_buf_hl)
    end
    for _, line in ipairs(match_line_option(contents, "modified")) do
        buffer.highlight_line(buf, line, "BMModBufHl", hl_config.mod_buf_hl)
    end
end

---Sets the cursor to the appropriate position during a refresh.
---@param reset boolean Default: false
local function position_cursor(reset, current_selection)
    local cur_buf_num = vim.api.nvim_win_get_buf(buffer_list_win.parent)
    local cur_buf_row = ui.find_buffer(cur_buf_num, buffer_list_win.buf)
    if reset then
        if cur_buf_row then
            vim.api.nvim_win_set_cursor(buffer_list_win.handle, { cur_buf_row, 0 })
        end
    else
        local selected_buf_row = ui.find_buffer(current_selection, buffer_list_win.buf)
        if selected_buf_row then
            vim.api.nvim_win_set_cursor(buffer_list_win.handle, { selected_buf_row, 0 })
        end
    end
end

---Updates the Buffer List Window with the latest buffer list.
---@param reset_cursor boolean|nil
local function refresh_buffer_manager_win(reset_cursor)
    reset_cursor = reset_cursor or false
    local current_selection = ui.select_buffer()
    local buf_list = {}
    if config.get_mode() == "marks" then
        ui.set_win_title(buffer_list_win.handle, " Mark Manager ")
        buf_list = mark.list()
    else
        ui.set_win_title(buffer_list_win.handle, " Buffer Manager ")
        config.set_mode("buffer")
        local ordering = config.get_runtime_option("buffer_list_ordering")
        buf_list = buffer.list(tostring(ordering))
    end
    local contents = format_buffer_list(buf_list)
    buffer.set_text(buffer_list_win.buf, contents)
    position_cursor(reset_cursor, current_selection)
    if config.get_buffer_list_value("use_hl_indicators") then
        add_indicator_highlights(buffer_list_win.buf)
    end
    if config.get_value("use_icons") and config.get_buffer_list_value("with_color") then
        for line_num, line in ipairs(contents) do
            highlight_icons_in_line(buffer_list_win.buf, line_num, line)
        end
    end
end

---Returns a table of lines containing the help text.
---@return table help_text
local function get_help_text()
    local help_text = {}
    help_text[#help_text + 1] = " Press '?' to go back"
    help_text[#help_text + 1] = "---------------------"
    for action, keys in pairs(config.get_buffer_list_value("keymaps")) do
        local fmt_action = string.gsub(string.format("%-15s", action), "_", " ")
        local keymap_str = "  " .. utils.caps(fmt_action) .. ": " .. keys.map
        help_text[#help_text + 1] = keymap_str
    end
    help_text[#help_text + 1] = ""
    help_text[#help_text + 1] = " Input Window"
    help_text[#help_text + 1] = "---------------------"
    for action, keys in pairs(config.get_input_win_value("keymaps")) do
        local fmt_action = string.gsub(string.format("%-15s", action), "_", " ")
        local keymap_str = "  " .. utils.caps(fmt_action) .. ": " .. keys
        help_text[#help_text + 1] = keymap_str
    end
    return help_text
end

---Displays or Clears the help information.
local function toggle_help()
    if config.get_mode() == "help" then
        config.set_mode(config.get_runtime_option("prev_mode"))
        refresh_buffer_manager_win(false)
    else
        config.set_mode("help")
        local help_text = get_help_text()
        buffer.set_text(buffer_list_win.buf, help_text)
    end
end

---Close the input window.
local function close_input_window()
    vim.cmd("stopinsert")
    ui.close(input_win)
    config.clear_context()
    if buffer_list_win.buf ~= nil then
        refresh_buffer_manager_win(false)
    end
end

---Close the buffer manager window.
---@param do_not_update_win boolean|nil
local function close_buffer_manager(do_not_update_win)
    ui.close(buffer_list_win)
    is_open = false
    vim.api.nvim_clear_autocmds({ group = "buff-man" })
    config.clear_context()
    if not do_not_update_win then
        vim.api.nvim_set_current_win(buffer_list_win.parent)
    end
end

---Process the user input and close the input_window.
---@param input_line integer
local function process_user_input(input_line)
    local input = unpack(vim.api.nvim_buf_get_lines(input_win.buf, input_line - 1, input_line, true))
    local ctx = config.get_context()
    M.process_action(ctx.action, { buf = ctx.buf, input_str = input })
    close_input_window()
    refresh_buffer_manager_win(false)
end

---Sets keymaps that disables keys that break the input window.
---@param input_line integer
local function set_safety_keymaps_for_input_window(input_line)
    -- The rest of these are to stop users from breaking things.
    -- I can probably get rid of these since it modifies user expected behavior.
    local buf = input_win.buf
    local win = input_win.handle
    vim.keymap.set({ "i", "n" }, "<BS>", function()
        local cur_pos_x, cur_pos_y = unpack(vim.api.nvim_win_get_cursor(win))
        if cur_pos_y == 0 or cur_pos_x ~= input_line then
            return ""
        else
            return "<BS>"
        end
    end, { expr = true, buffer = buf, nowait = true, silent = true })

    vim.keymap.set({ "i", "n" }, "<DEL>", function()
        local cur_pos_x, cur_pos_y = unpack(vim.api.nvim_win_get_cursor(win))
        local line = vim.api.nvim_buf_get_lines(buf, 0, -1, true)[input_line]
        if cur_pos_y == #line or cur_pos_x ~= input_line then
            return ""
        else
            return "<DEL>"
        end
    end, { expr = true, buffer = buf, nowait = true, silent = true })

    vim.keymap.set({ "i", "n" }, "<C-u>", function()
        return ""
    end, { expr = true, buffer = buf, nowait = true, silent = true })

    vim.keymap.set({ "i", "n" }, "<C-d>", function()
        return ""
    end, { expr = true, buffer = buf, nowait = true, silent = true })

    vim.keymap.set({ "i" }, "<C-w>", function()
        return ""
    end, { expr = true, buffer = buf, nowait = true, silent = true })
end

---Set the keymaps for the input buffer.
---@param input_line integer
local function set_keymaps_for_input_window(input_line)
    local buf = input_win.buf
    local keymaps = config.get_input_win_value("keymaps")
    vim.keymap.set({ "n", "i" }, keymaps.escape, function()
        close_input_window()
    end, { buffer = buf, nowait = true, noremap = true, silent = true })

    vim.keymap.set("n", keymaps.quit, function()
        close_input_window()
    end, { buffer = buf, nowait = true, noremap = true, silent = true })

    vim.keymap.set("i", keymaps.submit, function()
        process_user_input(input_line)
    end, { buffer = buf, nowait = true, noremap = true, silent = true })

    set_safety_keymaps_for_input_window(input_line)
end

---Sets up autocomplete to be used in the input window.
---@param buf integer The input window buffer.
---@param win_config table
---@param line number The line number of the input field.
local function setup_autocomplete(buf, win_config, line)
    local fmt = config.get_runtime_option("buffer_list_name_format") or "relative"
    local autocomplete_val = buffer.get_name(ui.select_buffer(), tostring(fmt))
    local namespace = config.get_value("namespace")
    local ext_id = vim.api.nvim_buf_set_extmark(buf, namespace, line - 1, 0, {
        virt_text = { { autocomplete_val, "BMAutoComplete" } },
        hl_mode = "combine",
        virt_text_win_col = 0,
    })
    vim.keymap.set("i", win_config.keymaps.autocomplete, function()
        vim.api.nvim_buf_del_extmark(buf, namespace, ext_id)
        buffer.set_text(buf, { autocomplete_val }, line - 1, line)
        local cur_pos = { line, #autocomplete_val + 1 }
        vim.api.nvim_win_set_cursor(input_win.handle, cur_pos)
    end, { buffer = buf, nowait = true, noremap = true, silent = true })
    vim.api.nvim_create_autocmd({ "InsertCharPre" }, {
        group = win_config.group,
        buffer = buf,
        callback = function()
            vim.api.nvim_buf_del_extmark(buf, namespace, ext_id)
        end,
    })
end

---Returns the help text for the input window.
---@param win_config table Th input window config.
---@return string input_help_text The help text.
local function get_input_window_help_text(win_config)
    local keymaps = win_config.keymaps
    local help_text = ""
    if win_config.show_help then
        help_text = keymaps.submit .. " to Submit.  "
        help_text = help_text .. keymaps.escape .. " to quit.  "
        if win_config.autocomplete then
            help_text = help_text .. keymaps.autocomplete .. " to autocomplete."
        end
    end
    return help_text
end

---Highlight the line used for input in the input win.
---@param input_line integer
local function highlight_input_line(input_line)
    local namespace = config.get_value("namespace")
    vim.api.nvim_win_set_hl_ns(input_win.handle, namespace)
    vim.api.nvim_buf_set_extmark(input_win.buf, namespace, input_line - 1, 0, {
        hl_group = "BMInputLine",
        end_line = input_line - 1,
        hl_eol = true,
        hl_mode = "combine",
        right_gravity = false,
        line_hl_group = "BMInputLine",
    })
end

---Setup the autocommands for the input window.
---@param input_line integer
---@param win_config table
local function setup_input_win_autocmds(input_line, win_config)
    -- This just protects user from themselves. It should probably be deleted.
    vim.api.nvim_create_autocmd({ "InsertCharPre" }, {
        group = win_config.group,
        buffer = input_win.buf,
        callback = function()
            local cur_pos_x = vim.api.nvim_win_get_cursor(input_win.handle)[1]
            if cur_pos_x ~= input_line then
                vim.api.nvim_win_set_cursor(input_win.handle, { input_line, 0 })
            end
        end,
    })
end

---Opens the Input Window.
---Opens a window ready to receive input from the user with the specified
---prompt. If no prompt is specified then "Input: " is used.
---@param prompt string|nil
local function open_input_window(prompt)
    local input_window_name = "buff-man-input"
    local input_window_config = config.get_value("input_window")
    input_win = ui.new(input_window_name, input_window_config)
    if vim.tbl_isempty(input_win) then
        vim.notify("ERROR: Could not open input window", vim.log.levels.ERROR)
        return
    end
    local input_help_text = get_input_window_help_text(input_window_config)
    local contents = { prompt or "Input: ", "", input_help_text }
    local input_line = table.maxn(contents) - 1
    buffer.set_text(input_win.buf, contents)
    if input_window_config.autocomplete then
        setup_autocomplete(input_win.buf, input_window_config, input_line)
    end
    highlight_input_line(input_line)
    setup_input_win_autocmds(input_line, input_window_config)
    set_keymaps_for_input_window(input_line)
    vim.api.nvim_set_current_win(input_win.handle)
    vim.api.nvim_win_set_cursor(input_win.handle, { input_line, 0 })
    vim.cmd("startinsert")
end

---Sets up to process an action after getting user input.
---@param action string
local function prompt_user_input(action)
    local selected_buffer = ui.select_buffer()
    if selected_buffer ~= nil then
        config.set_context({
            action = action,
            buf = selected_buffer,
            cur_pos = vim.api.nvim_win_get_cursor(buffer_list_win.handle),
        })
        open_input_window("New Buffer Name:")
    else
        local evnt = string.sub(action, 1, -7)
        vim.notify("ERROR: Cannot " .. evnt .. " buffer", vim.log.levels.ERROR)
    end
end

---Highlights the line the cursor is currently on.
local function highlight_current_line(buf)
    local line = vim.api.nvim_win_call(buffer_list_win.handle, function()
        return vim.api.nvim_win_get_cursor(0)[1] - 1
    end)
    local namespace = config.get_value("namespace")
    local win_config = config.get_value("buffer_list_window")
    vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
    local cur_line_hl = win_config.highlights.cur_line_hl
    vim.api.nvim_set_hl(0, "BMCurLine", cur_line_hl)
    vim.api.nvim_buf_set_extmark(buf, namespace, line, 0, {
        hl_group = "BMCurLine",
        end_line = line,
        hl_eol = true,
        hl_mode = "combine",
        right_gravity = false,
        line_hl_group = "BMCurLine",
    })
end

---Set the autocommands for the buffer manager.
local function set_autogroup_commands()
    local group = config.get_buffer_list_value("augroup")
    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        group = group,
        callback = function()
            local cur_win = vim.api.nvim_get_current_win()
            if cur_win ~= buffer_list_win.handle and cur_win ~= input_win.handle then
                close_buffer_manager()
                if input_win.handle ~= nil then
                    close_input_window()
                end
                return true
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = buffer_list_win.buf,
        group = group,
        callback = function()
            highlight_current_line(buffer_list_win.buf)
        end,
    })
end

---Processes the specified action.
---@param action string
---@param options table
function M.process_action(action, options)
    local buffer_selected = options.buf or ui.select_buffer()
    if type(buffer_selected) == "integer" and vim.api.nvim_buf_is_valid(buffer_selected) then
        buffer.ensure_loaded(buffer_selected)
    end

    -- Constant time but not as understandable as an if block
    local perform = {
        ["open"] = function(selected_buffer, _)
            local windows = vim.fn.win_findbuf(selected_buffer)
            if #windows ~= 0 and vim.api.nvim_win_is_valid(windows[1]) then
                vim.api.nvim_clear_autocmds({ group = "buff-man" })
                vim.api.nvim_set_current_win(windows[1])
            else
                buffer.open(selected_buffer, buffer_list_win.parent, {})
            end
            close_buffer_manager(true)
            return "nothing"
        end,
        ["open_cur"] = function(selected_buffer, _)
            buffer.open(selected_buffer, buffer_list_win.parent, {})
            return "close"
        end,
        ["v_open"] = function(selected_buffer, _)
            buffer.open(selected_buffer, buffer_list_win.parent, { split = "v" })
            return "close"
        end,
        ["h_open"] = function(selected_buffer, _)
            buffer.open(selected_buffer, buffer_list_win.parent, { split = "h" })
            return "close"
        end,
        ["delete"] = function(selected_buffer, opts)
            mark.remove(selected_buffer)
            buffer.delete(selected_buffer, opts.force)
        end,
        ["write"] = function(selected_buffer, _)
            buffer.write(selected_buffer)
        end,
        ["set_alternate"] = function(selected_buffer, _)
            buffer.set_alternate(selected_buffer, buffer_list_win.parent)
        end,
        ["rename"] = function(selected_buffer, opts)
            buffer.rename(selected_buffer, opts.input_str)
        end,
        ["copy"] = function(selected_buffer, opts)
            buffer.copy(selected_buffer, opts.input_str)
        end,
        ["new"] = function(_, opts)
            buffer.new(opts.input_str)
        end,
        ["mark"] = function(selected_buffer, _)
            mark.toggle(selected_buffer)
        end,
        ["prompt"] = function(_, opts)
            prompt_user_input(opts.prompt)
        end,
        ["show_marks"] = function()
            config.toggle_mode()
        end,
        ["quit"] = function(_, _)
            return "close"
        end,
        ["cycle"] = function(_, _)
            config.cycle_buffer_list_name_format()
        end,
        ["order"] = function(_, _)
            config.cycle_buffer_list_ordering()
        end,
        ["compact"] = function(_, _)
            config.toggle_buffer_list_compact()
        end,
        ["toggle_help"] = function(_, _)
            toggle_help()
            return "nothing"
        end,
        ["toggle_hidden"] = function(_, _)
            config.toggle_hidden_buffers()
        end,
        ["move_alternate"] = function(_, _)
            local alt_buf = buffer.get_alternate(buffer_list_win.parent)
            local alt_buf_line = ui.find_buffer(alt_buf, buffer_list_win.buf)
            if alt_buf_line then
                vim.api.nvim_win_set_cursor(buffer_list_win.handle, { alt_buf_line, 0 })
            end
        end,
        ["refresh_win"] = function(_, _)
            -- Do nothing to refresh the buffer
        end,
    }

    setmetatable(perform, {
        __index = function()
            return "nothing"
        end,
    })

    local post_action = perform[action](buffer_selected, options)
    if post_action == "close" then
        close_buffer_manager()
    elseif post_action ~= "nothing" then
        refresh_buffer_manager_win(false)
    end
end

---Set the keymaps for the buffer manager.
---@param keymaps table|nil
function M.set_keymaps_for_buffer_manager(keymaps)
    local buf = buffer_list_win.buf
    if vim.tbl_isempty(buffer_list_win) or not buf then
        vim.notify("ERROR: Buffer list window is invalid", vim.log.levels.ERROR)
        return
    end
    keymaps = keymaps or config.get_buffer_list_value("keymaps")
    config.set_buffer_list_keymaps(keymaps)
    if vim.tbl_isempty(keymaps) then
        vim.notify("WARNING: No keymaps to set", vim.log.levels.WARN)
        return
    end
    for action, keymap in pairs(keymaps) do
        if keymap.map == "" then
            goto continue -- Just Because it prevents even deeper indentation
        end
        local maps = keymap.map
        if type(keymap.map) ~= "table" then
            maps = { keymap.map }
        end
        for _, map in pairs(maps) do
            vim.keymap.set("n", map, function()
                M.process_action(keymap.action or action, keymap.opts or {})
            end, { buffer = buf, nowait = true, noremap = true, silent = true })
        end
        ::continue::
    end
end

---Open the buffer manager.
function M.open_buffer_manager()
    if is_open then
        return
    end
    local win_config = config.get_value("buffer_list_window")
    buffer_list_win = ui.new(win_config.name, win_config)
    if vim.tbl_isempty(buffer_list_win) or not buffer_list_win.handle then
        if buffer_list_win.buf then
            vim.api.nvim_buf_delete(buffer_list_win.buf, {})
            buffer_list_win.buf = nil
        end
        vim.notify("ERROR: Could not open Buffer Manager", vim.log.levels.ERROR)
        return
    end
    is_open = true
    refresh_buffer_manager_win(true)
    set_autogroup_commands()
    if win_config.use_keymaps then
        M.set_keymaps_for_buffer_manager()
    end
    vim.api.nvim_set_current_win(buffer_list_win.handle)
    vim.cmd("stopinsert")
end

---Setup the Buffer Manager
---@param opts table The config to setup the Buffer Manager.
function M.setup(opts)
    config.set_config(opts)
end

return M
