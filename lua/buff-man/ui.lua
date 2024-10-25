local M = {}

---Set the correct options for buff-man window buffers.
---@param buf integer The buffer to use.
---@param name string The name to use for the buffer.
---@param opts table The options used to configure the buffer.
local function set_buffer_options(buf, name, opts)
    local buffer_options = {
        ["modifiable"] = opts.modifiable or false,
        ["filetype"] = opts.filetype or "text",
        ["buftype"] = opts.buftype or "nowrite",
        ["bufhidden"] = opts.bufhidden or "delete",
        ["swapfile"] = opts.swapfile or false,
    }
    vim.api.nvim_buf_set_name(buf, name)
    for option, option_val in pairs(buffer_options) do
        vim.api.nvim_set_option_value(option, option_val, { buf = buf })
    end
end

---Create the buffer for the buff-man window and set all correct buffer
---options.
---@param name string The name to use for the buffer.
---@param opts table The options used to configure the buffer.
---@return integer win_buf The newly created buffer.
local function create_win_buffer(name, opts)
    local win_buf = vim.api.nvim_create_buf(false, false)
    if win_buf == 0 then
        vim.notify("ERROR: Cannot create buffer for window", vim.log.levels.ERROR)
    else
        set_buffer_options(win_buf, name, opts)
    end
    return win_buf
end

---Return the size of the parent container for the window. This container could
---be another window or the editor itself depending on settings.
---@param relative string The string representing if the window will be relative to the editor or window.
---@return table table The container width and height represented by the table {width, height}.
local function get_app_window_container_dimensions(relative)
    local container = vim.api.nvim_get_current_win()
    local container_width = vim.api.nvim_win_get_width(container)
    local container_height = vim.api.nvim_win_get_height(container)
    if relative == "editor" then
        container_width = vim.api.nvim_get_option_value("columns", {})
        container_height = vim.api.nvim_get_option_value("lines", {})
    end

    return { container_width, container_height }
end

local function set_app_window_size(container_dimensions, config)
    local container_width, container_height = unpack(container_dimensions)
    if string.match(config.width, "%.") then
        config.width = math.modf(container_width * config.width)
    end

    if string.match(config.height, "%.") then
        config.height = math.modf(container_height * config.height)
    end
end

local function set_app_window_placement(placement, container_dimensions, config)
    local container_width, container_height = unpack(container_dimensions)
    if placement == "top-left" then
        config.anchor = "NW"
        config.row = 0
        config.col = 0
    elseif placement == "top-right" then
        config.anchor = "NE"
        config.row = 0
        config.col = math.modf(container_width)
    elseif placement == "bot-right" then
        config.anchor = "SE"
        config.row = math.modf(container_height)
        config.col = math.modf(container_width)
    elseif placement == "bot-left" then
        config.anchor = "SW"
        config.row = math.modf(container_height)
        config.col = 0
    else -- Default: "center"
        config.anchor = "NW"
        config.row = math.modf((container_height / 2) - (config.height / 2))
        config.col = math.modf((container_width / 2) - (config.width / 2))
    end
end

local function create_app_window_config(name, opts)
    local config = {
        relative = opts.config.relative or "win",
        width = opts.width or 0.8,
        height = opts.height or 0.8,
        row = 1,
        col = 1,
        style = "minimal",
        border = "single",
        title = opts.title or (" " .. name .. " "),
        title_pos = "center",
    }
    local placement = opts.placement or "center"
    local container_dimensions = get_app_window_container_dimensions(config.relative)
    set_app_window_size(container_dimensions, config)
    set_app_window_placement(placement, container_dimensions, config)
    -- Override Window Config Values if Set
    for option, value in pairs(opts.config or {}) do
        config[option] = value
    end

    return config
end

local function set_app_window_options(win, opts)
    local win_set_option = vim.api.nvim_set_option_value
    local win_config = { win = win, scope = "local" }
    win_set_option("cursorline", opts.cursorline, win_config)
    win_set_option("number", opts.number or false, win_config)
    win_set_option("relativenumber", opts.relativenumber or false, win_config)
end

local function create_app_window(name, win_buf, opts)
    local config = create_app_window_config(name, opts)
    local win = vim.api.nvim_open_win(win_buf, false, config)
    if win == 0 then
        vim.notify("ERROR: Cannot create Window", vim.log.levels.ERROR)
        vim.api.nvim_buf_delete(win_buf, {})
        return
    end
    set_app_window_options(win, opts)
    return win
end

---Return the line of the cursor position of a given window or current window
---if win not specified.
---@param win integer|nil
---@return integer selection
function M.select_buffer(win)
    win = win or 0
    local selection = vim.api.nvim_win_call(win, function()
        return tonumber(string.match(vim.api.nvim_get_current_line(), "%d+"))
    end)
    return selection
end

---Find the line containing the buffer in the given window.
---@param buf_to_find integer
---@param buf_to_search integer
---@return integer | nil
function M.find_buffer(buf_to_find, buf_to_search)
    local buffer_list = vim.api.nvim_buf_get_lines(buf_to_search, 0, -1, true)
    for line_num, line in ipairs(buffer_list) do
        if buf_to_find == tonumber(string.match(line, "%d+")) then
            return line_num
        end
    end
    return nil
end

---Sets the title of the specified window.
---@param win integer
---@param title string
---@param pos string|nil Default: center
function M.set_win_title(win, title, pos)
    pos = pos or "center"
    vim.api.nvim_win_set_config(win, { title = title, title_pos = pos })
end

---Creates a new window and buffer and returns a table containing the window
---handle, the parent window handle, and the buffer created for the window. If
---the creation process fails an empty table is returned.
---@param name string A name to use for the buffer and the window.
---@param opts table Options for window.
---@return table window A table with handle to the window object.
function M.new(name, opts)
    local win_buf = create_win_buffer(name, opts)
    if win_buf == 0 then
        return {}
    end

    local win = create_app_window(name, win_buf, opts)
    if win == 0 then
        return {}
    end

    local window = {
        handle = win,
        parent = vim.api.nvim_get_current_win(),
        buf = win_buf,
    }
    return window
end

---Closes the window given by the table win.
---@param win table
function M.close(win, force)
    force = force or false
    if vim.api.nvim_get_current_win() == win.handle then
        vim.api.nvim_win_close(win.handle, force)
    end
    if win.buf ~= nil then
        vim.api.nvim_buf_delete(win.buf, {force = force})
    end
    win.handle = nil
    win.buf = nil
end

return M
