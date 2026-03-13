--[[
───────────────────────────────────────────────────────────────────────────────────────────────────────
─██████████████─██████──██████─██████████████─████████████████───████████████████───████████──████████─
─██░░░░░░░░░░██─██░░██──██░░██─██░░░░░░░░░░██─██░░░░░░░░░░░░██───██░░░░░░░░░░░░██───██░░░░██──██░░░░██─
─██░░██████████─██░░██──██░░██─██░░██████████─██░░████████░░██───██░░████████░░██───████░░██──██░░████─
─██░░██─────────██░░██──██░░██─██░░██─────────██░░██────██░░██───██░░██────██░░██─────██░░░░██░░░░██───
─██░░██─────────██░░██████░░██─██░░██████████─██░░████████░░██───██░░████████░░██─────████░░░░░░████───
─██░░██─────────██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░░░░░░░░░██───██░░░░░░░░░░░░██───────████░░████─────
─██░░██─────────██░░██████░░██─██░░██████████─██░░██████░░████───██░░██████░░████─────────██░░██───────
─██░░██─────────██░░██──██░░██─██░░██─────────██░░██──██░░██─────██░░██──██░░██───────────██░░██───────
─██░░██████████─██░░██──██░░██─██░░██████████─██░░██──██░░██████─██░░██──██░░██████───────██░░██───────
─██░░░░░░░░░░██─██░░██──██░░██─██░░░░░░░░░░██─██░░██──██░░░░░░██─██░░██──██░░░░░░██───────██░░██───────
─██████████████─██████──██████─██████████████─██████──██████████─██████──██████████───────██████───────
───────────────────────────────────────────────────────────────────────────────────────────────────────

    Cherry is a UI Layout Library for CC:Tweaked* using Lua**
    Originally inspired by Clay (https://www.youtube.com/watch?v=by9lQvpvMIc)
    Implemented with the help of this guide: https://tchayen.com/how-to-write-a-flexbox-layout-engine

    *  https://tweaked.cc
    ** https://www.lua.org/about.html

    Usage example: https://pastebin.com/ghC6YS70

    Colors:
        0: Transparent
        1: White
        2: Orange
        4: Magenta
        8: Light Blue
        16: Yellow
        32: Lime
        64: Pink
        128: Gray
        256: Light Gray
        512: Cyan
        1024: Purple
        2048: Blue
        4096: Brown
        8192: Green
        16384: Red
        32768: Black
--]]

--- Main Object Class
local Object = {}
Object.__index = Object

--- Creates a new Object
function Object:new()
end

--- Returns an object that extends this one.
--- @return table
function Object:extend()
    local obj = {}
    for key, value in pairs(self) do
        if key:find("__") then
            obj[key] = value
        end
    end
    obj.__index = obj
    obj.super = self
    setmetatable(obj, self)
    return obj
end

--- Overrides the call functionality of the Object to return a new instance of the Object.
--- @param ... unknown
--- @return table
function Object:__call(...)
    local obj = setmetatable({}, self)
---@diagnostic disable-next-line: redundant-parameter
    obj:new(...)
    return obj
end

local function debug(...)
    local t = term.current()
    term.redirect(term.native())
    print(...)
    term.redirect(t)
end

local function render(node)
    local list = {}

    local queue = {}

    table.insert(queue, 1, node)

    while #queue > 0 do
        local nextNode = table.remove(queue, 1)

        list[#list+1] = nextNode.value

        local p = nextNode.lastChild
        while p do
            if p.value.input.display ~= "none" then
                table.insert(queue, 1, p)
            end
            p = p.prev
        end
    end

    table.sort(list, function (a, b)
        return a.zIndex < b.zIndex
    end)

    for _, view in ipairs(list) do
        local prev = term.current()
        term.redirect(view.window)
        if view.input.text then
            term.setTextColor(view.input.color)
            term.setCursorPos(view.x, view.y)
            term.write(view.input.text)
        elseif view.backgroundColor ~= 0 then
            term.setBackgroundColor(view.backgroundColor)
            term.clear()
        end
        term.redirect(prev)
    end
end

local function measure(node)
    local input = node.value.input

    if type(input.width) == "number" then
        node.value.width = input.width
    end

    if type(input.height) == "number" then
        node.value.height = input.height
    end

    local totalAlong = node.value:getSize("along")
    local maxAcross = node.value:getSize("across")

    local childrenCount = 0

    local child = node.firstChild

     while child do
        if child.value.input.position == "relative" then
            totalAlong = totalAlong + child.value:getSize("along", input.flexDirection)
            maxAcross = math.max(maxAcross, (child.value:getSize("across", input.flexDirection)))

            childrenCount = childrenCount + 1
        end

        child = child.next
    end

    totalAlong = totalAlong + math.max(0, childrenCount - 1) * input.gap
    totalAlong = totalAlong + input:getPadding("along"):sum()
    maxAcross = maxAcross + input:getPadding("across"):sum()

    node.value:setSize(totalAlong, "along")
    node.value:setSize(maxAcross, "across")
end

local function calculate(root)
    local firstPass = {}
    local secondPass = {}
    local forwardQueue = {}

    local function toPercentage(value)
        if type(value) ~= "string" or value:sub(#value) ~= "%" then
            error("Value must be a percentage.")
        end

        return tonumber(value:sub(1, #value-1))
    end

    table.insert(firstPass, 1, root)

    -- First pass.
    -- Gathers order for later passes.
    while next(firstPass) do
        local element = table.remove(firstPass)

        local child = element.firstChild
        while child do
            firstPass[#firstPass+1] = child
            secondPass[#secondPass+1] = child
            child = child.next
        end
    end

    -- Second pass (bottom-up). 
    -- Resolves widths and heights of parents that didn't have them explicitly.
    while next(secondPass) do
        local element = table.remove(secondPass, 1)

        forwardQueue[#forwardQueue+1] = element

        measure(element)
    end

    -- Final pass (top-down).
    -- Applies top/left/bottom/right, calculates alignSelf, calculates available space, applies justifyContent and alignItems.
    while next(forwardQueue) do
        local element = table.remove(forwardQueue, 1)

        local parent = element.parent

        local input = element.value.input
        local parentInput = parent.value.input

        local parentAlong = parent.value:getSize("along") or 0
        local parentAcross = parent.value:getSize("across") or 0

        local paddingAlong = input:getPadding("along")
        local paddingAcross = input:getPadding("across")

        local parentPaddingAlong = parentInput:getPadding("along")
        local parentPaddingAcross = parentInput:getPadding("across")

        if input.flex < 0 then
            error("Flex cannot be negative.")
        end

        if type(input:getSize("along")) == "string" then
            element.value:setSize(toPercentage(input:getSize("along")) * parentAlong, "along")
        end

        if type(input:getSize("across")) == "string" then
            element.value:setSize(toPercentage(input:getSize("across")) * parentAcross, "across")
        end

        local types = { "along", "across" }
        for _, type in ipairs(types) do
            local directions = input:getDirections(type)
            local parentPosition = (parent.value:getPosition(type) or 0)
            if directions.x and directions.y and not input:getSize(type) then
                element.value:setPosition(parentPosition + directions.x, type)
                element.value:setSize(parent.value:getSize(type) - directions.x - directions.y, type)
            elseif not directions.x then
                if input.position == "absolute" then
                    element.value:setPosition(parentPosition + directions.x, type)
                else
                    element.value:setPosition(element.value:getPosition(type) + directions.x, type)
                end
            elseif not directions.y then
                if input.position == "absolute" then
                    element.value:setPosition(parentPosition + (parent.value:getSize(type) or 0) - directions.y - element.value:getSize(type), type)
                else
                    element.value:setPosition(parentPosition - directions.y, type)
                end
            elseif input.position == "absolute" then
                element.value:setPosition(parentPosition, type)
            end
        end

        -- Apply Align Self
        if input.position ~= "absolute" and parent then
            if input.alignSelf == "center" then
                element.value:setPosition(element.value:getPosition("along") + element.value:getSize("along") / 2 - element.value:getSize("along") / 2, "along")
                element.value:setPosition(element.value:getPosition("across") + element.value:getSize("across") / 2 - element.value:getSize("across") / 2, "across")
            end

            if input.alignSelf == "flex-end" then
                element.value:setPosition(
                    element.value:getPosition("along") +
                    parent.value:getSize("along") -
                    element.value:getSize("along") -
                    parentPaddingAlong.x -
                    parentPaddingAlong.y
                ,"along")
                element.value:setPosition(
                    element.value:getPosition("across") +
                    parent.value:getSize("across") -
                    element.value:getSize("across") -
                    parentPaddingAcross.x -
                    parentPaddingAcross.y
                ,"across")
            end

            if input.alignSelf == "stretch" then
                element.value:setSize(
                    parent.value:getSize("along") -
                    parentPaddingAlong.x -
                    parentPaddingAlong.y
                , "along")
                element.value:setSize(
                    parent.value:getSize("across") -
                    parentPaddingAcross.x -
                    parentPaddingAcross.y
                , "across")
            end
        end

        -- Set percentage sizes
        do
            local child = element.firstChild
            while child do
                if type(child.value.input:getSize("along")) == "string" then
                    child.value:setSize(
                        toPercentage(child.value.input:getSize("along")) *
                        element.value:getSize("along")
                    , "along")
                end
                if type(child.value.input:getSize("across")) == "string" then
                    child.value:setSize(
                        toPercentage(child.value.input:getSize("across")) *
                        element.value:getSize("across")
                    , "across")
                end

                child = child.next
            end
        end

        element.value.zIndex = input.zIndex or parent.value.zIndex or 0

        local availableAlong = element.value:getSize("along")
        local availableAcross = element.value:getSize("across")

        local childrenCount = 0
        local totalFlex = 0

        do
            local child = element.firstChild
            while child do
                if child.value.input.position == "relative" then
                    childrenCount = childrenCount + 1
                end

                -- TODO: Investigate if flex should be compared to nil or 0
                if child.value.input.flex == nil and child.value.input.position == "relative" then
                    availableAlong = availableAlong - child.value:getSize("along")
                    availableAcross = availableAcross - child.value:getSize("across")
                end

                if child.value.input.flex ~= nil then
                    totalFlex = totalFlex + child.value.input.flex
                end

                child = child.next
            end
        end

        local justifyContentNotSpace =
            input.justifyContent ~= "space-between" and
            input.justifyContent ~= "space-around" and
            input.justifyContent ~= "space-evenly"

        availableAlong =
            availableAlong -
            paddingAlong.x +
            paddingAlong.y +
            ((justifyContentNotSpace) and (childrenCount - 1) * input.gap or 0)
        availableAcross =
            availableAcross -
            paddingAcross.x +
            paddingAcross.y

        -- Apply sizes
        do
            local child = element.firstChild
            while child do
                if child.value.input.flex ~= nil and justifyContentNotSpace then
                    child.value:setSize((child.value.input.flex / totalFlex) * availableAlong, "along")
                end
                child = child.next
            end
        end

        element.value:setPosition(element.value:getPosition("along") + select(1, input:getMargin("along")), "along")
        element.value:setPosition(element.value:getPosition("across") + select(1, input:getMargin("across")), "across")

        local alongPos = element.value:getPosition("along") + select(1, input:getPadding("along"))
        local acrossPos = element.value:getPosition("across") + select(1, input:getPadding("across"))

        if input.justifyContent == "center" then
            alongPos = alongPos + availableAlong / 2
            acrossPos = acrossPos + availableAcross / 2
        end

        if input.justifyContent == "flex-end" then
            alongPos = alongPos + availableAlong
            acrossPos = acrossPos + availableAcross
        end

        if input.justifyContent == "space-between" or
        input.justifyContent == "space-around" or
        input.justifyContent == "space-evenly" then
            local count =
                childrenCount +
                ((input.justifyContent == "space-between") and -1
                or (input.justifyContent == "space-evenly") and 1
                or 0)
            count = math.max(count, 1)

            local alongGap = availableAlong / count
            local acrossGap = availableAcross / count

            local child = element.firstChild
            while child do
                child.value:setPosition(
                    alongPos +
                    ((input.justifyContent == "space-between") and 0 or
                    (input.justifyContent == "space-around") and alongGap / 2 or alongGap)
                , "along")
                child.value:setPosition(
                    acrossPos +
                    ((input.justifyContent == "space-between") and 0 or
                    (input.justifyContent == "space-around") and acrossGap / 2 or acrossGap)
                , "across")

                alongPos = alongPos + child.value:getSize("along") + alongGap
                acrossPos = acrossPos + child.value:getSize("across") + acrossGap

                child = child.next
            end
        else
            local child = element.firstChild
            while child do
                if child.value.input.position ~= "absolute" and child.value.input.display ~= "none" then
                    child.value:setPosition(alongPos, "along")
                    alongPos = alongPos + child.value:getSize("along")
                    alongPos = alongPos + input.gap

                    child.value:setPosition(acrossPos + child.value:getPosition("across"), "across")
                end

                child = child.next
            end
        end

        -- Align items
        do
            local child = element.firstChild
            while child do
                if child.value.input.position ~= "absolute" then
                    if input.alignItems == "center" then
                        child.value:setPosition(
                            element.value:getPosition("across") +
                            element.value:getSize("across") / 2 -
                            child.value:getSize("across") / 2
                        , "across")
                        child.value:setPosition(
                            element.value:getPosition("along") +
                            element.value:getSize("along") / 2 -
                            child.value:getSize("along") / 2
                        , "along")
                    end

                    if input.alignItems == "flex-end" then
                        child.value:setPosition(
                            element.value:getPosition("across") +
                            element.value:getSize("across") -
                            child.value:getSize("across") -
                            paddingAcross.y
                        , "across")
                        child.value:setPosition(
                            element.value:getPosition("along") +
                            element.value:getSize("along") -
                            child.value:getSize("along") -
                            paddingAlong.y
                        , "along")
                    end

                    if input.alignItems == "stretch" then
                        if child.value:getSize("across") == nil then
                            child.value:setSize(
                                element.value:getSize("across") -
                                paddingAcross.x -
                                paddingAcross.y
                            , "across")
                        end
                        if child.value:getSize("along") == nil then
                            child.value:setSize(
                                element.value:getSize("along") -
                                paddingAlong.x -
                                paddingAlong.y
                            , "along")
                        end
                    end
                end

                child = child.next
            end
        end

        element.value:setPosition(math.floor(element.value:getPosition("along")), "along")
        element.value:setPosition(math.floor(element.value:getPosition("across")), "across")
        element.value:setSize(math.floor(element.value:getSize("along")), "along")
        element.value:setSize(math.floor(element.value:getSize("across")), "across")
    end

    local child = root.firstChild
    while child do
        local value = child.value
        local parentWindow = child.parent.value.window or term.current()
        value.window = window.create(parentWindow, value.x, value.y, value.width, value.height)

        child = child.next
    end
end

local Vector2 = Object:extend()
local ViewStyle = Object:extend()
local TextStyle = Object:extend()
local FixedView = Object:extend()
local CherryTree = FixedView:extend()

local Cherry = {
    --- Responsible for creating the Node Tree.
    --- Type is view or string.
    --- @param type string
    --- @param properties table
    __call = function(type, properties)
        if type == "view" then
            local style = ViewStyle(properties)
            local node = CherryTree{
                input = style,
                table.unpack(properties)
            }

            local children = properties.children or {}
            for _, child in ipairs(children) do
                if child then
                    node:addChild(child)
                end
            end

            return node
        end

        if type == "text" then
            if _G.type(properties.children) ~= "string" then
                error("Text children must be a string.", 2)
            end

            local style = TextStyle(properties)

            local height = 1
            local width = #properties.children -- ???

            local input = {
                table.unpack(style),
                table.unpack(ViewStyle()),
                width = width,
                height = height,
                text = properties.children
            }

            local node = CherryTree{
                input = input,
                table.unpack(properties),
                width = width,
                height = height
            }

            return node
        end

        error("Invalid type.", 2)
    end
}

--- All supported properties.
--- When resolving padding/margin, priority goes:
--- left/right/top/bottom -> horizontal/vertical -> base
function ViewStyle:new(properties)
    self.width = properties.width -- number | % | nil
    self.height = properties.height -- number | % | nil

    self.flexDirection = properties.flexDirection or "row" -- "row" | "column"
    self.justifyContent = properties.justifyContent or "flex-start"
        -- "flex-start"
        -- "center"
        -- "flex-end"
        -- "space-between"
        -- "space-around"
        -- "space-evenly"
    self.alignItems = properties.alignItems or "flex-start" -- "flex-start" | "center" | "flex-end" | "stretch"
    self.alignSelf = properties.alignSelf or "flex-start" -- "flex-start" | "center" | "flex-end" | "stretch"

    self.flex = properties.flex or 0 -- number
    self.position = properties.position or "relative" -- "relative" | "absolute"
    self.gap = properties.gap or 0 -- number
    self.zIndex = properties.zIndex or 0 -- number
    self.display = properties.display or "flex" -- "flex" | "none"

    self.top = properties.top or 0 -- number
    self.left = properties.left or 0 -- number
    self.right = properties.right or 0 -- number
    self.bottom = properties.bottom or 0 -- number

    self.padding = properties.padding or 0 -- number
    self.paddingHorizontal = properties.paddingHorizontal or 0 -- number
    self.paddingVertical = properties.paddingVertical or 0 -- number
    self.paddingLeft = properties.paddingLeft or 0 -- number
    self.paddingRight = properties.paddingRight or 0 -- number
    self.paddingTop = properties.paddingTop or 0 -- number
    self.paddingBottom = properties.paddingBottom or 0 -- number

    self.margin = properties.margin or 0 -- number
    self.marginHorizontal = properties.marginHorizontal or 0 -- number
    self.marginVertical = properties.marginVertical or 0 -- number
    self.marginLeft = properties.marginLeft or 0 -- number
    self.marginRight = properties.marginRight or 0 -- number
    self.marginTop = properties.marginTop or 0 -- number
    self.marginBottom = properties.marginBottom or 0 -- number

    self.backgroundColor = properties.backgroundColor or 0 -- number
end

--- Gets the size of the Node based on side and flexDirection.
--- Defaults to nodes own flexDirection.
--- @param side string
--- @param flexDirection string|nil
--- @return number
function ViewStyle:getSize(side, flexDirection)
    flexDirection = flexDirection or self.flexDirection

    if flexDirection == "row" then
        if side == "along" then
            return self.width
        elseif side == "across" then
            return self.height
        else
            error("Invalid side.", 2)
        end
    elseif flexDirection == "column" then
        if side == "along" then
            return self.height
        elseif side == "across" then
            return self.width
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Gets the directions of the Node based on side and flexDirection. (top & botton or left & right)
--- Defaults to nodes own flexDirection.
--- @param side string
--- @param flexDirection string|nil
--- @return number
function ViewStyle:getDirections(side, flexDirection)
    flexDirection = flexDirection or self.flexDirection

    if flexDirection == "row" then
        if side == "along" then
            return Vector2(self.left, self.right)
        elseif side == "across" then
            return Vector2(self.top, self.bottom)
        else
            error("Invalid side.", 2)
        end
    elseif flexDirection == "column" then
        if side == "along" then
            return Vector2(self.top, self.bottom)
        elseif side == "across" then
            return Vector2(self.left, self.right)
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Gets the directions of the Node based on side and flexDirection. (top & botton or left & right)
--- Defaults to nodes own flexDirection.
--- @param side string
--- @param flexDirection string|nil
--- @return number
function ViewStyle:getPadding(side, flexDirection)
    flexDirection = flexDirection or self.flexDirection

    if flexDirection == "row" then
        if side == "along" then
            return Vector2(self.paddingLeft, self.paddingRight)
        elseif side == "across" then
            return Vector2(self.paddingTop, self.paddingBottom)
        else
            error("Invalid side.", 2)
        end
    elseif flexDirection == "column" then
        if side == "along" then
            return Vector2(self.paddingTop, self.paddingBottom)
        elseif side == "across" then
            return Vector2(self.paddingLeft, self.paddingRight)
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Gets the directions of the Node based on side and flexDirection. (top & botton or left & right)
--- Defaults to nodes own flexDirection.
--- @param side string
--- @param flexDirection string|nil
--- @return number
function ViewStyle:getMargin(side, flexDirection)
    flexDirection = flexDirection or self.flexDirection

    if flexDirection == "row" then
        if side == "along" then
            return Vector2(self.marginLeft, self.marginRight)
        elseif side == "across" then
            return Vector2(self.marginTop, self.marginBottom)
        else
            error("Invalid side.", 2)
        end
    elseif flexDirection == "column" then
        if side == "along" then
            return Vector2(self.marginTop, self.marginBottom)
        elseif side == "across" then
            return Vector2(self.marginLeft, self.marginRight)
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Extra properties for text.
function TextStyle:new(properties)
    self.text = properties.text or "" -- string
    self.color = properties.color or 1 -- number
end

--- View with all layout properties resolved.
function FixedView:new(properties)
    self.input = type(properties.input) == "table" and properties.input or {} -- ViewStyle | TextStyle
    self.x = type(properties.x) == "number" and properties.x or 0 -- number
    self.y = type(properties.y) == "number" and properties.y or 0 -- number
    self.width = type(properties.width) == "number" and properties.width or 0 -- number
    self.height = type(properties.height) == "number" and properties.height or 0 -- number
    self.zIndex = type(properties.zIndex) == "number" and properties.zIndex or 0 -- number
    self.backgroundColor = type(properties.backgroundColor) == "number" and properties.backgroundColor or 0 -- number
    self.window = {}
end

--- Gets the size of the Node based on side and flexDirection.
--- Defaults to nodes own flexDirection.
--- @param side string
--- @param flexDirection string|nil
--- @return number
function FixedView:getSize(side, flexDirection)
    flexDirection = flexDirection or self.input.flexDirection

    if flexDirection == "row" then
        if side == "along" then
            return self.width
        elseif side == "across" then
            return self.height
        else
            error("Invalid side.", 2)
        end
    elseif flexDirection == "column" then
        if side == "along" then
            return self.height
        elseif side == "across" then
            return self.width
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Gets the size of the Node based on side and flexDirection.
--- Defaults to nodes own flexDirection.
--- @param size number
--- @param side string
--- @param flexDirection string|nil
function FixedView:setSize(size, side, flexDirection)
    flexDirection = flexDirection or self.input.flexDirection
    size = math.floor(size)

    if flexDirection == "row" then
        if side == "along" then
            self.width = size
        elseif side == "across" then
            self.height = size
        else
            error("Invalid side.", 2)
        end
    elseif flexDirection == "column" then
        if side == "along" then
            self.height = size
        elseif side == "across" then
            self.width = size
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Gets the size of the Node based on side and flexDirection.
--- Defaults to nodes own flexDirection.
--- @param side string
--- @param flexDirection string|nil
function FixedView:getPosition(side, flexDirection)
    flexDirection = flexDirection or self.input.flexDirection

    if flexDirection == "row" then
        if side == "along" then
            return self.x
        elseif side == "across" then
            return self.y
        else
            error("Invalid side.", 2)
        end
    elseif flexDirection == "column" then
        if side == "along" then
            return self.y
        elseif side == "across" then
            return self.x
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Gets the size of the Node based on side and flexDirection.
--- Defaults to nodes own flexDirection.
--- @param coord number
--- @param side string
--- @param flexDirection string|nil
function FixedView:setPosition(coord, side, flexDirection)
    flexDirection = flexDirection or self.input.flexDirection

    if flexDirection == "row" then
        if side == "along" then
            self.x = coord
        elseif side == "across" then
            self.y = coord
        else
            error("Invalid side.", 2)
        end
    elseif flexDirection == "column" then
        if side == "along" then
            self.y = coord
        elseif side == "across" then
            self.x = coord
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Creates a new Tree.
function CherryTree:new(properties)
    self.value = FixedView(properties)
    self.next = nil
    self.prev = nil
    self.firstChild = nil
    self.lastChild = nil
    self.parent = nil
end

--- Adds a child to the Tree.
function CherryTree:addChild(node)
    node.parent = self

    if next(self.firstChild) then
        if next(self.lastChild) == nil then
            error("Last child must be set.")
        end

        node.prev = self.lastChild
        self.lastChild.next = node
        self.lastChild = node
    else
        self.firstChild = node
        self.lastChild = node
    end

    return node
end

--- Creates a new Vector2
--- @param x number
--- @param y number
function Vector2:new(x, y)
    self.x = (type(x) == "number") and x or 0
    self.y = (type(y) == "number") and y or 0
end

--- Adds 2 Vector2s together.
function Vector2:add(other)
    local x =
        (self.x or self[1]) +
        ((type(other) == "table") and (other.x or other[1] or 0) or 0)
    local y =
        (self.y or self[2]) +
        ((type(other) == "table") and (other.y or other[2] or 0) or 0)
	return Vector2(x, y)
end
Vector2.__add = Vector2.add

--- Gets the sum of the Vector2.
--- @return number
function Vector2:sum()
    return self.x + self.y
end

return { Cherry = Cherry, render = render, calculate = calculate }
