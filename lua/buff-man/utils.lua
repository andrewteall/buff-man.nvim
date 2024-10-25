local M = {}

---Performs a logical XOR on two values a and b
---@param a any
---@param b any
---@return boolean boolean
function M.xor(a, b)
    return (a and not b) or (not a and b)
end

---Capitalize each word in the specified string.
---@param sentence string
---@return string,number|nil string,number|nil
function M.caps(sentence)
    return string.gsub(sentence, "(%a)([%w_']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end)
end

function M.is_option(option)
    local options = vim.api.nvim_get_all_options_info()
    if options[option] then
        return true
    else
        return false
    end
end

function M.is_nerd_font_icon(byte_sequence)
    local codepoint = nil
    if #byte_sequence == 1 then
        codepoint = byte_sequence:byte(1)
    elseif #byte_sequence == 2 then
        codepoint = (byte_sequence:byte(1) - 192) * 64 + (byte_sequence:byte(2) - 128)
    elseif #byte_sequence == 3 then
        codepoint = (byte_sequence:byte(1) - 224) * 4096
            + (byte_sequence:byte(2) - 128) * 64
            + (byte_sequence:byte(3) - 128)
    elseif #byte_sequence == 4 then
        codepoint = (byte_sequence:byte(1) - 240) * 262144
            + (byte_sequence:byte(2) - 128) * 4096
            + (byte_sequence:byte(3) - 128) * 64
            + (byte_sequence:byte(4) - 128)
    end
    if
        (codepoint >= 0xE000 and codepoint <= 0xF8FF)
        or (codepoint >= 0x1F300 and codepoint <= 0x1F5FF)
        or(codepoint >= 0x1F900 and codepoint <= 0x1F9FF)
        -- codepoint >= 0x1000
    then
        return true
    end
    return false
end

function M.get_character_size(byte)
    local char_size = 1
    -- Determine the size of the UTF-8 character based on the first byte
    if byte >= 240 then
        char_size = 4
    elseif byte >= 224 then
        char_size = 3
    elseif byte >= 192 then
        char_size = 2
    end
    return char_size
end
return M
