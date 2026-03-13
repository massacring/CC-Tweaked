local function getItems(detailed)
    local items = {}
    for i = 1, 16, 1 do
        table.insert(items, turtle.getItemDetail(i, detailed))
    end
    return items
end

local function getItemIndex(name)
    for i = 1, 16, 1 do
        local item = turtle.getItemDetail(i)
        if not item then goto continue end

        if item.name == name then return i end

        ::continue::
    end
    error("Item not found.", 2)
end

return { getItems = getItems, getItemIndex = getItemIndex }