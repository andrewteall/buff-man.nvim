local M = {}

local mark_list = {}

---Finds a buffer in the mark list. Returns nil if not found.
---@param buf integer The mark to find in the list.
---@return integer|nil idx The idx of the found mark or nil if not found.
function M.find(buf)
    for idx, mark in ipairs(mark_list) do
        if mark == buf then
            return idx
        end
    end
    return nil
end

---Adds a mark to the mark list if it does not exist.
---@param mark integer The mark to be added to the mark list.
function M.add(mark)
    if not M.find(mark) then
        table.insert(mark_list, mark)
    end
end

---Removes a mark from the mark list if it does not exist.
---@param mark integer The mark to be removed from the mark list.
function M.remove(mark)
    local idx = M.find(mark)
    if idx then
        table.remove(mark_list, idx)
    end
end

---Removes or Adds a mark to the mark list based whether or not it is found.
---@param mark integer The mark to be removed or added to the mark list.
function M.toggle(mark)
    if M.find(mark) then
        M.remove(mark)
    else
        M.add(mark)
    end
end

---Returns the List of marks.
---@return table mark_list The list of marks contained in the mark list.
function M.list()
    return mark_list
end

---Returns the lowest numbered mark in the mark list.
---@return integer lowest_mark_idx The lowest mark index in the mark list.
function M.get_lowest_mark_idx()
    local lowest_mark_idx = 1
    for idx, mark in ipairs(mark_list) do
        if mark < mark_list[lowest_mark_idx] then
            lowest_mark_idx = idx
        end
    end
    return lowest_mark_idx
end

---Returns the highest numbered Mark in the Mark list.
---@return integer highest_mark_idx The highest mark index in the mark list.
function M.get_highest_mark()
    local highest_mark_idx = 1
    for idx, mark in ipairs(mark_list) do
        if mark > mark_list[highest_mark_idx] then
            highest_mark_idx = idx
        end
    end
    return highest_mark_idx
end

---Returns the next Mark in the list based on the current Mark.
---@param mark integer
---@return integer integer
function M.get_next(mark)
    if #mark_list == 0 then
        return mark
    end

    local idx = M.find(mark)
    if not idx then
        return mark_list[1]
    end
    if idx == #mark_list then
        return mark_list[1]
    else
        return mark_list[idx + 1]
    end
end

---Returns the previous Mark in the list based on the current Mark.
---@param mark integer
---@return integer integer
function M.get_prev(mark)
    if #mark_list == 0 then
        return mark
    end

    local idx = M.find(mark)
    if not idx then
        return mark_list[#mark_list]
    end
    if idx == 1 then
        return mark_list[#mark_list]
    else
        return mark_list[idx - 1]
    end
end

return M
