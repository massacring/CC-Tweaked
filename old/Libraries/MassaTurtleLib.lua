local function getItems(detailed)
    if not detailed then detailed = false end
    local items = {}
    for i = 1, 16, 1 do
        table.insert(items, turtle.getItemDetail(i, detailed))
    end
    return items
end

local function getItemIndex(identifier)
    local id, tag
    if string.sub(identifier, 1, 1) == "#" then
        tag = identifier:sub(2)
    else
        id = identifier
    end
    for i = 1, 16, 1 do
        local item = turtle.getItemDetail(i, true)
        if not item then goto continue end

        if tag and item.tags then
            if item.tags[tag] then return i end
        else
            if item.name == id then return i end
        end

        ::continue::
    end
    error("Item not found.", 2)
end

return { getItems = getItems, getItemIndex = getItemIndex }