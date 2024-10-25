local M = {}

local config = {}

local runtime_opts = {
    show_hidden = false,
    buffer_list_name_format = "relative", -- 'full', 'short'
    buffer_list_ordering = "inorder", -- 'mru'
    buffer_list_compact = false,
    buffer_list_line_format = "fisnslm",
    buffer_list_compact_line_format = "sisn",
    mode = "buffer", -- 'mark', 'help'
    prev_mode = "",
    context = {},
}

function M.get_runtime_option(option)
    return runtime_opts[option]
end

function M.set_runtime_option(option, value)
    runtime_opts[option] = value
end

function M.toggle_hidden_buffers()
    runtime_opts.show_hidden = not runtime_opts.show_hidden
end

function M.cycle_buffer_list_name_format()
    local format = {
        ["relative"] = "full",
        ["full"] = "short",
        ["short"] = "relative",
    }
    runtime_opts.buffer_list_name_format = format[runtime_opts.buffer_list_name_format]
end

function M.cycle_buffer_list_ordering()
    local order = {
        ["inorder"] = "mru",
        ["mru"] = "inorder",
    }
    runtime_opts.buffer_list_ordering = order[runtime_opts.buffer_list_ordering]
end

function M.toggle_buffer_list_compact()
    runtime_opts.buffer_list_compact = not runtime_opts.buffer_list_compact
end

function M.get_buffer_list_line_format()
    if runtime_opts.buffer_list_compact then
        return runtime_opts.buffer_list_compact_line_format
    else
        return runtime_opts.buffer_list_line_format
    end
end

function M.set_mode(mode)
    runtime_opts.prev_mode = runtime_opts.mode
    runtime_opts.mode = mode
end

function M.get_mode()
    return runtime_opts.mode
end

function M.toggle_mode()
    if M.get_mode() == "marks" then
        M.set_mode(M.get_runtime_option("prev_mode"))
    else
        M.set_mode("marks")
    end
end

function M.set_context(ctx)
    runtime_opts.context = ctx
end

function M.get_context()
    return runtime_opts.context
end

function M.clear_context()
    runtime_opts.context = {}
end

--------------------------------------------------------------------------------
local function init_opts_table(opts)
    opts.buffer_list_window = opts.buffer_list_window or {}
    opts.buffer_list_window.keymaps = opts.buffer_list_window.keymaps or {}
    opts.buffer_list_window.highlights = opts.buffer_list_window.highlights or {}
    opts.buffer_list_window.config = opts.buffer_list_window.config or {}
    opts.input_window = opts.input_window or {}
    opts.input_window.keymaps = opts.input_window.keymaps or {}
    opts.input_window.highlights = opts.input_window.highlights or {}
    opts.input_window.config = opts.input_window.config or {}

    -- Figure out a better way
    opts.buffer_list_window.keymaps.open = opts.buffer_list_window.keymaps.open or {}
    opts.buffer_list_window.keymaps.open_cur = opts.buffer_list_window.keymaps.open_cur or {}
    opts.buffer_list_window.keymaps.v_open = opts.buffer_list_window.keymaps.v_open or {}
    opts.buffer_list_window.keymaps.h_open = opts.buffer_list_window.keymaps.h_open or {}
    opts.buffer_list_window.keymaps.quit = opts.buffer_list_window.keymaps.quit or {}
    opts.buffer_list_window.keymaps.delete = opts.buffer_list_window.keymaps.delete or {}
    opts.buffer_list_window.keymaps.force_delete = opts.buffer_list_window.keymaps.force_delete or {}
    opts.buffer_list_window.keymaps.write = opts.buffer_list_window.keymaps.write or {}
    opts.buffer_list_window.keymaps.set_alt = opts.buffer_list_window.keymaps.set_alt or {}
    opts.buffer_list_window.keymaps.move_alt = opts.buffer_list_window.keymaps.move_alt or {}
    opts.buffer_list_window.keymaps.mark = opts.buffer_list_window.keymaps.mark or {}
    opts.buffer_list_window.keymaps.show_marks = opts.buffer_list_window.keymaps.show_marks or {}
    opts.buffer_list_window.keymaps.rename = opts.buffer_list_window.keymaps.rename or {}
    opts.buffer_list_window.keymaps.copy = opts.buffer_list_window.keymaps.copy or {}
    opts.buffer_list_window.keymaps.new = opts.buffer_list_window.keymaps.new or {}
    opts.buffer_list_window.keymaps.toggle_hidden = opts.buffer_list_window.keymaps.toggle_hidden or {}
    opts.buffer_list_window.keymaps.cycle = opts.buffer_list_window.keymaps.cycle or {}
    opts.buffer_list_window.keymaps.ordering = opts.buffer_list_window.keymaps.ordering or {}
    opts.buffer_list_window.keymaps.compact = opts.buffer_list_window.keymaps.compact or {}
    opts.buffer_list_window.keymaps.refresh_win = opts.buffer_list_window.keymaps.refresh_win or {}
end

function M.set_config(opts)
    if not opts then
        opts = {}
    end
    init_opts_table(opts)

    ---The configuration used to launch the plugin.
    ---@class config
    ---@field namespace integer The namespace for the buff-man plugin.
    ---@field use_icons boolean Whether or not to use icons beside the name.
    ---@field buffer_list_window table The configuration for the buffer list window.
    ---@field input_window table The configuration for the input window.
    config = {
        namespace = vim.api.nvim_create_namespace("buff-man"),
        use_icons = opts.use_dev_icons or false,
        buffer_list_window = {
            name = "buff-man",
            filetype = "buff-man",
            augroup = vim.api.nvim_create_augroup("buff-man", { clear = true }),
            config = {},
            use_keymaps = (opts.buffer_list_window.use_keymaps == nil) or (opts.buffer_list_window.use_keymaps == true),
            title = opts.buffer_list_window.title or " Buffer Manager ",
            placement = opts.buffer_list_window.placement, -- "top-left", "top-right", "bot-right", "bot-left", "center"
            width = opts.buffer_list_window.width,
            height = opts.buffer_list_window.height,
            ordering = opts.buffer_list_window.ordering or M.get_runtime_option("buffer_list_ordering"),
            compact = opts.buffer_list_window.compact or M.get_runtime_option("buffer_list_compact"),
            show_hidden = opts.buffer_list_window.show_hidden or M.get_runtime_option("show_hidden"),
            cursorline = opts.buffer_list_window.cursorline or false,
            number = opts.buffer_list_window.number or false,
            relativenumber = opts.buffer_list_window.relativenumber or false,
            format = opts.buffer_list_window.format or M.get_runtime_option("buffer_list_name_format"),
            line_format = opts.buffer_list_window.line_format or M.get_buffer_list_line_format(),
            compact_line_format = opts.buffer_list_window.compact_line_format
                or M.get_runtime_option("buffer_list_compact_line_format"),
            filename_width = opts.buffer_list_window.filename_width or 41,
            with_color = (opts.buffer_list_window.with_color == nil) or (opts.buffer_list_window.with_color == true),
            use_hl_indicators = (opts.buffer_list_window.use_hl_indicators == nil)
                or (opts.buffer_list_window.use_hl_indicators == true),
            highlights = {
                cur_buf_hl = opts.buffer_list_window.highlights.cur_buf_hl or { italic = false, bold = true },
                alt_buf_hl = opts.buffer_list_window.highlights.alt_buf_hl or { italic = true, bold = false },
                mod_buf_hl = opts.buffer_list_window.highlights.mod_buf_hl or { link = "WarningMsg" },
                -- mod_buf_hl = opts.buffer_list_window.highlights.mod_buf_hl or { fg = "#ff0000", ctermfg = 9 },
                hid_buf_hl = opts.buffer_list_window.highlights.hid_buf_hl or {},
                cur_line_hl = opts.buffer_list_window.highlights.cur_line_hl or { link = "CursorLine" },
            },
            keymaps = {
                open = {
                    map = opts.buffer_list_window.keymaps.open.map or "e",
                    action = "open",
                },
                open_cur = {
                    map = opts.buffer_list_window.keymaps.open_cur.map or "<CR>",
                    action = "open_cur",
                },
                v_open = {
                    map = opts.buffer_list_window.keymaps.v_open.map or "v",
                    action = "v_open",
                    opts = {},
                },
                h_open = {
                    map = opts.buffer_list_window.keymaps.h_open.map or "h",
                    action = "h_open",
                },
                escape = {
                    map = "<ESC>",
                    action = "quit",
                },
                quit = {
                    map = opts.buffer_list_window.keymaps.quit.map or "q",
                    action = "quit",
                },
                delete = {
                    map = opts.buffer_list_window.keymaps.delete.map or "d",
                    action = "delete",
                },
                force_delete = {
                    map = opts.buffer_list_window.keymaps.force_delete.map or "fd",
                    action = "delete",
                    opts = { force = true },
                },
                write = {
                    map = opts.buffer_list_window.keymaps.write.map or "w",
                    action = "write",
                },
                set_alt = {
                    map = opts.buffer_list_window.keymaps.set_alt.map or "#",
                    action = "set_alternate",
                },
                move_alt = {
                    map = opts.buffer_list_window.keymaps.move_alt.map or "a",
                    action = "move_alternate",
                },
                mark = {
                    map = opts.buffer_list_window.keymaps.mark.map or "m",
                    action = "mark",
                },
                show_marks = {
                    map = opts.buffer_list_window.keymaps.show_marks.map or "s",
                    action = "show_marks",
                },
                rename = {
                    map = opts.buffer_list_window.keymaps.rename.map or "r",
                    action = "prompt",
                    opts = { prompt = "rename" },
                },
                copy = {
                    map = opts.buffer_list_window.keymaps.copy.map or "c",
                    action = "prompt",
                    opts = { prompt = "copy" },
                },
                new = {
                    map = opts.buffer_list_window.keymaps.new.map or "n",
                    action = "prompt",
                    opts = { prompt = "new" },
                },
                toggle_hidden = {
                    map = opts.buffer_list_window.keymaps.toggle_hidden.map or ".",
                    action = "toggle_hidden",
                },
                cycle = {
                    map = opts.buffer_list_window.keymaps.cycle.map or "l",
                    action = "cycle",
                },
                ordering = {
                    map = opts.buffer_list_window.keymaps.ordering.map or "o",
                    action = "order",
                },
                compact = {
                    map = opts.buffer_list_window.keymaps.compact.map or "t",
                    action = "compact",
                },
                help = { map = "?", action = "toggle_help" },
                refresh_win = {
                    map = opts.buffer_list_window.keymaps.refresh_win.map or "R",
                    action = "refresh_win",
                },
            },
        },
        input_window = {
            title = opts.input_window.title or " Input ",
            group = vim.api.nvim_create_augroup("buff-man-input", { clear = true }),
            placement = opts.input_window.placement,
            width = opts.input_window.width,
            height = opts.input_window.height or 3,
            cursorline = opts.input_window.cursorline or false,
            modifiable = true,
            autocomplete = (opts.input_window.autocomplete == nil) or (opts.input_window.autocomplete == true),
            filetype = "buff-man",
            show_help = (opts.input_window.show_help == nil) or (opts.input_window.show_help == true),
            config = {},
            keymaps = {
                autocomplete = opts.input_window.keymaps.autocomplete or "<C-y>",
                quit = opts.input_window.keymaps.quit or "q",
                escape = opts.input_window.keymaps.escape or "<ESC>",
                submit = opts.input_window.keymaps.submit or "<CR>",
            },
            highlights = {
                autocomplete_hl = opts.input_window.highlights.autocomplete_hl
                    or { fg = "#8a8a8a", ctermfg = 245, italic = true, bold = false },
                input_line_hl = opts.input_window.highlights.input_line_hl or { link = "CursorLine" },
            },
        },
    }

    for option, value in pairs(opts.config or {}) do
        config.buffer_list_window.config[option] = value
        config.input_window.config[option] = value
    end

    for option, value in pairs(opts.buffer_list_window.config or {}) do
        config.buffer_list_window.config[option] = value
    end

    for option, value in pairs(opts.input_window.config or {}) do
        config.input_window.config[option] = value
    end

    M.set_runtime_option("show_hidden", config.buffer_list_window.show_hidden)
    M.set_runtime_option("buffer_list_name_format", config.buffer_list_window.format)
    M.set_runtime_option("buffer_list_ordering", config.buffer_list_window.ordering)
    M.set_runtime_option("buffer_list_compact", config.buffer_list_window.compact)
    if type(config.buffer_list_window.line_format) == "string" then
        M.set_runtime_option("buffer_list_line_format", config.buffer_list_window.line_format)
    else
        vim.notify("ERROR: Invalid Line Format.", vim.log.levels.ERROR)
    end
    if type(config.buffer_list_window.compact_line_format) == "string" then
        M.set_runtime_option("buffer_list_compact_line_format", config.buffer_list_window.compact_line_format)
    else
        vim.notify("ERROR: Invalid Compact Line Format.", vim.log.levels.ERROR)
    end

    local autocomplete_hl = config.input_window.highlights.autocomplete_hl
    vim.api.nvim_set_hl(config.namespace, "BMAutoComplete", autocomplete_hl)
    local input_line_hl = config.input_window.highlights.input_line_hl
    vim.api.nvim_set_hl(config.namespace, "BMInputLine", input_line_hl)
end

function M.set_buffer_list_keymaps(keymaps)
    config.buffer_list_window.keymaps = keymaps
end

function M.get_config()
    return config
end

function M.get_value(value)
    return config[value]
end

function M.get_buffer_list_value(value)
    return config.buffer_list_window[value]
end

function M.get_input_win_value(value)
    return config.input_window[value]
end

return M
