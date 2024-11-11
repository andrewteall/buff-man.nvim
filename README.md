# Buff-Man.nvim

Buff-Man.nvim is a full featured buffer manager for Neovim.

!["Buff-Man.nvim screenshot"](https://github.com/user-attachments/assets/fbffe90f-8947-4afc-b005-cb271c013d64)
## Requirements

- Neovim ≥ v0.9
- (Optional) A patched [nerd font](https://www.nerdfonts.com/)
- (Optional) [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)

## Installation

You can install Buff-Man.nvim with your plugin manager of choice. If you use
`lazy.nvim`, simply add to your plugin list:

```lua
-- Lua
return {
  'andrewteall/buff-man.nvim',
  opts = {}
}
```

## Configuration

Buff-Man.nvim is configured with the following defaults.

```lua
    opts = {
        -- Allow nvim-web-devicons to be used in the buffer line.
        use_icons = false,

        -- The list of configuration options specific to the main window of the
        -- Buffer Manager.
        buffer_list_window = {

            -- Whether or not to use the provided keymaps. Useful if you want to
            -- only use a couple keymaps. Instead of overriding them all you can
            -- set set `use_keymaps` to false and the use the
            -- `set_keymaps_for_buffer_manger(keymaps)` function to set only
            -- the keymaps you want to use. There are additional parameters that
            -- must be provided if doing this and can be found in
            -- `lua/buff-man/config.lua. It's probably best to copy that keymaps
            -- table and edit it to your liking. This will rarely be needed as
            -- you can just edit the keymaps below and set the keymap to "" if
            -- you don't wish to use it.
            -- DO NOT CHANGE THIS VALUE UNLESS YOU KNOW WHAT YOU ARE DOING!!!
            use_keymaps = true,

            -- Set the title of the Buffer Manager window. Purely cosmetic. Set
            -- to "" if you want no title to be shown.
            title = " Buffer Manager ",

            -- Window placement of the Buffer Manager window. These are relative
            -- to the parent container that is specified by
            -- `relative=editor/win` in the config below. 
            -- Accepted values are: "top-left", "top-right", "bot-right",
            -- "bot-left", or "center"
            placement = "center",

            -- Width of the window. Numbers less than 0 are calculated of a
            -- percent of the parent window.
            width = 0.8, -- 80% of the parent window

            -- Height of the window. Numbers less than 0 are calculated of a
            -- percent of the parent window.
            height = 0.8, -- 80% of the parent window

            -- Odering of the list of buffers. Default is "inorder" meaning
            -- buffers are displayed by buffer number ascending. "mru" orders
            -- the buffers by most recently used.
            ordering = "inorder", -- "mru" 

            -- Whether or not to use the compact line format specified below by
            -- default. This can be toggled with a keymaps specified below.
            compact = true,

            -- Whether or not to show hidden files by default. This can be 
            -- toggled with a keymaps specified below.
            show_hidden = false,

            -- Whether or not to show the cursorline in the Buffer Manager
            -- window. This is mostly superceded by the current line highlight
            -- below but if that fails this may be a solid backup.
            cursorline = false,

            -- Show Line numbers on the Buffer Manager window.
            number = false,

            -- Show Relative Line numbers on the Buffer Manager window.
            relativenumber = false,

            -- Default filename format used by the Buffer Manager. All formats 
            -- can be cycled through with a keymap specified below.
            format = "relative",  -- "full", "short"

            -- The line format displayed by the Buffer Manager. The buffer
            -- number will always be displayed first. Each letter in the
            -- supplied string will be decoded into different sections of a
            -- buffer line.
            -- "b" = The buffer number
            -- "f" = The buffer flags. See `:buffers` output.
            -- "s" = " " A literal space.
            -- "i" = The icon from nvim-web-devicons. use_icons must be true.
            -- "n" = The buffer name in the specified format.
            -- "l" = The line count of the buffer
            -- "t" = The filetype
            -- "m" = Whether or not the file is marked.
            line_format =  "fsisnslm",

            -- Same as line format above but when `compact=true`
            compact_line_format = "sisn",

            -- With amount of chacters reserved to print the buffer name on the
            -- line. Can be used to fine tune spacing and cosmetics.
            filename_width = 41,

            -- Add the nvim-web-devicons color to the icons on the menu is used.
            -- Otherwise the icons will be black.
            with_color = true,

            -- The config maps to the config for `nvim_open_win()`. It allows
            -- you to override any values available there for the buffer list
            -- window if a means is not already provied. A notable exception are
            -- the width and height parameters since they are available above.
            config = {},

            -- Use the highlights specified below to indicate certain lines in
            -- the buffer list such as the current buffer, the alternate buffer,
            -- hidden buffers, and modified buffers. This setting does not
            -- affect the Current Line highlight below.
            use_hl_indicators = true,
            highlights = {
                -- Current Buffer
                cur_buf_hl = { italic = false, bold = true },

                -- Alternate Buffer
                alt_buf_hl = { italic = true, bold = false },

                -- Modified Buffers
                mod_buf_hl = { link = "WarningMsg" },

                -- Hidden Buffers
                hid_buf_hl = {},

                -- Current Line
                cur_line_hl = { link = "CursorLine" },

            },

            -- The default keymaps used by the Buffer Manager. Map can be set to
            -- a table with multiple keymaps defined such as:
            -- keymaps = {
            --      open = {
            --          map = { "<CR>", "<ESC>" }
            --      }
            -- }
            -- or as a string
            keymaps = {
                -- Open the buffer indicated by the line you are on in the
                -- current window. If the buffer is open in another window you 
                -- will be moved to that window.
                open = {
                    map = "e",
                },

                -- Open the buffer indicated by the line you are on in the
                -- current window regardless if the buffer is open in another
                -- window. 
                open_cur = {
                    map = "<CR>",
                },

                -- Open the buffer indicated by the line you are on in a new
                -- vertical window.
                v_open = {
                    map = "v",
                },

                -- Open the buffer indicated by the line you are on in a new
                -- horizontal window.
                h_open = {
                    map = "h",
                },

                -- Close the Buffer Manager Window.
                quit = {
                    map = "q",
                },

                -- Delete the buffer specified by the line you are on.
                delete = {
                    map = "d",
                },

                -- Delete the buffer specified by the line you are on and
                -- provide the force parameter to delete the buffer even if it
                -- has been modified.
                force_delete = {
                    map = "fd",
                },

                -- Write the buffer specified by the line you are on.
                write = {
                    map = "w",
                },

                -- Move the cursor to the line with the alternate buffer
                set_alt = {
                    map = "#",
                },

                -- Set the alternate buffer for the current window to the line
                -- the cursor is currently on.
                move_alt = {
                    map = "a",
                },

                -- Mark the buffer the cursor is currently on.
                mark = {
                    map = "m",
                },

                -- Toggle viewing the marked buffers vs all buffers.
                show_marks = {
                    map = "s",
                },

                -- Rename the buffer the cursor is currently on.
                rename = {
                    map = "r",
                },

                -- Copy the buffer the cursor is currently on.
                copy = {
                    map = "c",
                },

                -- Create a new buffer.
                new = {
                    map = "n",
                },

                -- Toggle showing hidden buffers.
                toggle_hidden = {
                    map = ".",
                },

                -- Cycle through the available name formats.
                cycle = {
                    map = "l",
                },

                -- Toggle the ordering between inorder and mru.
                ordering = {
                    map = "o",
                },

                -- Switch the buffer line to compact mode.
                compact = {
                    map = "t",
                },

                -- Refresh the buffer window.                
                refresh_win = {
                    map = "R",
                },
            },
        },

        -- The list of configuration options specific to the input window of the
        -- Buffer Manager.
        input_window = {

            -- Set the title of the Input window. Purely cosmetic. Set title
            -- to "" if you want no title to be shown.
            title = " Input ",

            -- Window placement of the Buffer Manager window. These are relative
            -- to the parent container that is specified by
            -- `relative=editor/win` in the config below. 
            -- Accepted values are: "top-left", "top-right", "bot-right",
            -- "bot-left", or "center"
            placement = "center",

            -- Width of the window. Numbers less than 0 are calculated of a
            -- percent of the parent window.
            width = 0.8, -- 80% of the parent window

            -- Height of the window. Numbers less than 0 are calculated of a
            -- percent of the parent window.
            height = 3,

            -- Whether or not to show the cursorline in the Input window. This
            -- is mostly superceded by the current line highlight below but if
            -- that fails this may be a solid backup.
            cursorline = false,

            -- Allows for autocompletion of the currently selected line's buffer
            -- name with a keymap. Regular completion via plugins is not
            -- affected.
            autocomplete = true,

            -- Shows the keymaps on the 3rd line of the Input window.
            show_help = true,

            -- The config maps to the config for `nvim_open_win()`. It allows
            -- you to override any values available there for the input window
            -- if a means is not already provied. A notable exception are the
            -- width and height parameters since they are available above.
            config = {},

            -- The default keymaps used by the Input window.
            keymaps = {
                -- Keymap to trigger the autocompletion mentioned above
                autocomplete = "<C-y>",

                -- Close the input window in Normal Mode. 
                escape = "<ESC>",

                -- Submit the text in the Input window to be processed.
                submit = "<CR>",
            },

            highlights = {
                autocomplete_hl = { fg = "#8a8a8a", ctermfg = 245, italic = true },
                input_line_hl = { link = "CursorLine" },
            },
        },

        -- The config maps to the config for `nvim_open_win()`. It allows
        -- you to override any values available there for the both windows
        -- if a means is not already provied. A notable exception are the
        -- width and height parameters since they are available above.
        config = {},
    }
```

## Usage

Open the Buffer Manager window with `:BuffManOpen`. This will open Buffer
Manager in the last mode you were using.

Alternatively you can open the Buffer Manager window with `:BuffManBufferOpen`
or `:BuffManMarkOpen` to open the Buffer Manager in Buffer mode or Mark mode
respectively.

You can navigate Marked files with the `:BuffManMarkNext` and `:BuffManMarkPrev`
commands and toggle a file being marked outside of the Buffer Window with the
`:BuffManMarkToggle` command.

A typical use case is to map one of all of these to a keymap.

When the Buffer Manager is open you can use "\<ESC\>" to close the window and
"?" to show the help window. Neither of the keymaps can be remapped in the
configureation to provide a way to always close the window and show the help.

## License
This software project is licensed under the MIT-0 License. You are free to use,
modify, and distribute the project according to the terms of the license.
