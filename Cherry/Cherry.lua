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

    Cherry is a UI Layout Library for CC:Tweaked* using Lua**.

    *  https://tweaked.cc
    ** https://www.lua.org/about.html

    Usage example: https://pastebin.com/ghC6YS70

    Colors:
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
local Cherry = {}
Cherry.__index = Cherry

--- Creates a new Object
function Cherry:new()
end

--- Returns an object that extends this one.
--- @return table
function Cherry:extend()
    local cherry = {}
    for key, value in pairs(self) do
        if key:find("__") then
            cherry[key] = value
        end
    end
    cherry.__index = cherry
    cherry.super = self
    setmetatable(cherry, self)
    return cherry
end

--- Implements the functions of objects.
--- @param ... table
function Cherry:implement(...)
  for _, cherry in pairs({...}) do
    for key, value in pairs(cherry) do
      if self[key] == nil and type(value) == "function" then
        self[key] = value
      end
    end
  end
end

--- Overrides the call functionality of the Object to return a new instance of the Object.
--- @param ... unknown
--- @return table
function Cherry:__call(...)
    local cherry = setmetatable({}, self)
---@diagnostic disable-next-line: redundant-parameter
    cherry:new(...)
    return cherry
end

local UIElement = Cherry:extend()
local Label = UIElement:extend()
local Button = UIElement:extend()
local Vector2 = Cherry:extend()

local LayoutManager = {
    root = {},
    elements = {},
    elementsByClosing = {},
    textElements = {},
    buttonElements = {},
}

--- Returns a function that determines the element width and size to FIT.
--- @param properties table|nil
--- @return function
LayoutManager.FIT = function(properties)
    properties = (type(properties) == "table") and properties or {}
    local min = properties.min
    local max = properties.max
    min = (type(min) == "number") and math.max(0, min) or 0
    max = (type(max) == "number") and math.max(0, max) or math.maxinteger
    return function ()
        return { type = "FIT", size = 0, min = min, max = max }
    end
end

--- Returns a function that determines the element width and size to FIXED.
--- @param num number
--- @return function
LayoutManager.FIXED = function(num)
    num = (type(num) == "number") and num or 0
    return function ()
        return { type = "FIXED", size = num, min = num, max = num }
    end
end

--- Returns a function that determines the element width and size to GROW.
--- @param properties table|nil
--- @return function
LayoutManager.GROW = function(properties)
    properties = (type(properties) == "table") and properties or {}
    local min = properties.min
    local max = properties.max
    local factor = properties.factor or 1
    min = (type(min) == "number") and math.max(0, min) or 0
    max = (type(max) == "number") and math.max(0, max) or math.maxinteger
    factor = (type(factor) == "number") and math.max(1, factor) or 1
    return function ()
        return { type = "GROW", size = 0, min = min, max = max, factor = factor }
    end
end

--- Draws a rectangle.
--- @param properties table
LayoutManager.drawRectangle = function(properties)
    setmetatable(properties, {__index={
        position = Vector2(0, 0),
        size = Vector2(0, 0),
        color = 1,
    }})
    if properties.window == nil then
        error("You must specify a window to draw on.", 2)
    end
    properties.window.setCursorPos(properties.position.x, properties.position.y)
    properties.window.setBackgroundColor(properties.color)
    for row = 1, properties.size.y, 1 do
        properties.window.setCursorPos(properties.position.x, properties.position.y+row-1)
        properties.window.write(string.rep(" ", properties.size.x))
    end
end

--- Returns a function that opens a UIElement with the specified properties and optional children.
--- @param properties table
--- @return function
LayoutManager.openUIElement = function(properties)
    --- @param children table|nil
    --- @return table
    return function (children)
        return {
            properties = properties,
            children = children or {}
        }
    end
end

--- Builds a UIElement based on the specification table and its children.
--- @param spec table
--- @param parent table|nil
--- @return table
LayoutManager.buildUIElement = function(spec, parent)
    -- Opening.
    --print("Opened: " .. spec.properties.name)

    if not spec then error("", 2) end
    spec.properties.parent = parent
    local element
    if spec.properties.onClick then
        element = Button(spec.properties)
    elseif spec.properties.text then
        element = Label(spec.properties)
    else
        element = UIElement(spec.properties)
    end

    for _, childSpec in ipairs(spec.children) do
        local child = LayoutManager.buildUIElement(childSpec, element)
        table.insert(element.children, child)
    end

    -- Closing
    table.insert(LayoutManager.elementsByClosing, element)
    --print("Closed: " .. spec.properties.name)

    return element
end

--- Calculates proper sizing and positions.
function LayoutManager:layout()
    -- Fit Sizing
    for _, element in ipairs(self.elementsByClosing) do
        element:measure()
    end
    -- Grow And Shrink Sizing
    self.root:growAndShrinkChildElements()
    -- Wrap Text

    -- Fit Re-Sizing
    -- for _, element in ipairs(self.elementsByClosing) do
    --     element:measure()
    -- end
    -- Grow And Shrink Re-Sizing
    -- self.root:growAndShrinkChildElements()
    -- Position Elements
    self.root:_setLayoutPositionRecursive()
    self.root:_setDrawPositionRecursive()
end

--- Creates a new UIElement Object
--- @param properties table
function UIElement:new(properties)
    if not (properties ~= nil and type(properties) == "table") then
        error("Invalid properties when creating new UIElement.", 3)
    end
    setmetatable(properties, {__index={
        direction = (properties.parent ~= nil and properties.parent.direction ~= nil and properties.parent.direction or "LEFT_TO_RIGHT"),
        position = { 0, 0 },
        size = { LayoutManager.FIT(), LayoutManager.FIT() },
        padding = { left = 0, top = 0, right = 0, bottom = 0 },
        childGap = 0,
        backgroundColor = 1
    }})

    self.parent = properties.parent
    LayoutManager.elements[self] = true
    if not self.parent then
        LayoutManager.root = self
    end

    if not (type(properties.direction) == "string" and (properties.direction == "TOP_TO_BOTTOM" or properties.direction == "LEFT_TO_RIGHT")) then
        error("Invalid direction when creating new UIElement.", 3)
    end
    self.direction = properties.direction

    if not (type(properties.position) == "table" and (#properties.position == 2 or (properties.x ~= nil and properties.y ~= nil))) then
        error("Invalid position when creating new UIElement.", 3)
    end
    local x, y =
        properties.position.x or properties.position[1],
        properties.position.y or properties.position[2]
    if not (x ~= nil and y ~= nil and type(x) == "number" and type(y) == "number") then
        error("Invalid position when creating new UIElement.", 3)
    end
    self.layoutPosition = Vector2(x, y)
    self.drawPosition = Vector2(x, y)
    self.layoutX = x
    self.drawX = x
    self.layoutY = y
    self.drawY = y

    if not (type(properties.size) == "table" and #properties.size == 2 and type(properties.size[1]) == "function" and type(properties.size[2]) == "function") then
        error("Invalid size when creating new UIElement.", 3)
    end

    local widthProperties = properties.size[1]()
    if widthProperties.type == "GROW" then
        self.widthGrow = widthProperties.factor
    end
    self.widthMinimum = widthProperties.min
    self.widthMaximum = widthProperties.max
    self.widthSizing = widthProperties.type
    self.width = widthProperties.size

    local heightProperties = properties.size[2]()
    if heightProperties.type == "GROW" then
        self.heightGrow = heightProperties.factor
    end
    self.heightMinimum = heightProperties.min
    self.heightMaximum = heightProperties.max
    self.heightSizing = heightProperties.type
    self.height = heightProperties.size

    self.size = Vector2(self.width, self.height)

    if not (type(properties.padding) == "table" and
    ((#properties.padding >= 1 and #properties.padding <= 4) or
    (properties.padding.left ~= nil or properties.padding.top ~= nil or properties.padding.right ~= nil or properties.padding.bottom ~= nil))) then
        error("Invalid padding when creating new UIElement.", 3)
    end
    local left, top, right, bottom = 0, 0, 0, 0
    for key, value in pairs(properties.padding) do
        if type(key) == "number" then
            if key == 1 then
                left = value
            elseif key == 2 then
                top = value
            elseif key == 3 then
                right = value
            elseif key == 4 then
                bottom = value
            end
        elseif type(key) == "string" then
            if key == "left" then
                left = value
            elseif key == "top" then
                top = value
            elseif key == "right" then
                right = value
            elseif key == "bottom" then
                bottom = value
            end
        end
    end
    self.padding = { left = left, top = top, right = right, bottom = bottom }

    if not (type(properties.childGap) == "number") then
        error("Invalid childGap when creating new UIElement.", 3)
    end
    self.childGap = properties.childGap
    if not (type(properties.backgroundColor) == "number") then
        error("Invalid backgroundColor when creating new UIElement.", 3)
    end
    self.backgroundColor = properties.backgroundColor

    self.children = {}
end

--- Measures Fit Sizing for this UI element.
function UIElement:measure()
    local totalAlong = select(1, self:getSize("along"))
    local maxAcross = select(1, self:getSize("across"))

    for _, child in ipairs(self.children) do
        totalAlong = totalAlong + (child:getSize("along", self.direction))
        maxAcross = math.max(maxAcross, (child:getSize("across", self.direction)))
    end

    totalAlong = totalAlong + math.max(0, #self.children - 1) * self.childGap
    totalAlong = totalAlong + self:getPadding("along"):sum()
    maxAcross = maxAcross + self:getPadding("across"):sum()

    if self.text then
        local words = {}
        for str in string.gmatch(self.text, "([^".." ".."]+)") do
            table.insert(words, str)
        end

        local textHeight = #words
        local textWidth = 0
        for _, word in ipairs(words) do
            textWidth = math.max(textWidth or 0, #word)
        end

        self.widthMinimum = textWidth + self.padding.right + self.padding.left
        self.widthMaximum = #self.text + self.padding.right + self.padding.left
        self.heightMinimum = 1 + self.padding.top + self.padding.bottom
        self.heightMaximum = textHeight + self.padding.top + self.padding.bottom
    end

    if self:getSizing("along") == "FIT" then
        self:setSize(totalAlong, "min", "along")
    end
    if self:getSizing("across") == "FIT" then
        self:setSize(maxAcross, "min", "across")
    end
end

function UIElement:growAndShrinkChildElements()
    local totalAlong = self:getSize("along")
    local padding = self:getPadding("along"):sum()
    local gaps = math.max(0, #self.children - 1) * self.childGap

    local baseTotal = padding + gaps

    local items = {}

    for _, child in ipairs(self.children) do
        local size, min = child:getSize("along", self.direction)

        table.insert(items, {
            child = child,
            base = size,
            size = size,
            min = min,
            grow = child:getSizing("along", self.direction) == "GROW"
                and (child:getGrowthFactor("along", self.direction) or 1)
                or 0,
            shrink = 1
        })

        baseTotal = baseTotal + size
    end

    local freeSpace = totalAlong - baseTotal

    if freeSpace > 0 then
        local totalGrow = 0
        for _, item in ipairs(items) do
            totalGrow = totalGrow + item.grow
        end

        if totalGrow > 0 then
            for _, item in ipairs(items) do
                if item.grow > 0 then
                    local add = freeSpace * (item.grow / totalGrow)
                    item.size = item.size + add
                end
            end
        end
    end

    if freeSpace < 0 then
        local deficit = -freeSpace

        local shrinking = true

        while shrinking and deficit > 0 do
            shrinking = false

            local totalShrink = 0
            for _, item in ipairs(items) do
                if item.size > item.min then
                    totalShrink = totalShrink + item.shrink
                end
            end

            if totalShrink == 0 then break end

            for _, item in ipairs(items) do
                if item.size > item.min then
                    local remove = deficit * (item.shrink / totalShrink)
                    local newSize = math.max(item.min, item.size - remove)

                    deficit = deficit - (item.size - newSize)
                    item.size = newSize

                    shrinking = true
                end
            end
        end
    end

    for _, item in ipairs(items) do
        item.child:setSize(item.size, "size", "along", self.direction)
    end

    for _, item in ipairs(items) do
        item.child:growAndShrinkChildElements()
    end
end

function UIElement:arrange(finalAlongSize, finalAcrossSize)
    if finalAlongSize then self:setSize(finalAlongSize, "along") end
    if finalAcrossSize then self:setSize(finalAcrossSize, "across") end

    local totalAlong = (self:getSize("along"))
    local padding = self:getPadding("along"):sum()
    local gaps = math.max(0, #self.children - 1) * self.childGap
    local used = padding
    local growChildren = {}

    for _, child in ipairs(self.children) do
        if child:getSizing("along", self.direction) == "GROW" then
            table.insert(growChildren, child)
        else
            used = used + (child:getSize("along", self.direction))
        end
    end

    local remaining = totalAlong - used - gaps
    if remaining > 0 and #growChildren > 0 then
        local each = math.floor(remaining / #growChildren)
        local remainder = remaining % #growChildren
        for i, child in ipairs(growChildren) do
            local alongSize = each + (i == #growChildren and remainder or 0)
            child:setSize(alongSize, "along", self.direction)
        end
    end

    local acrossSize = (self:getSize("across")) - self:getPadding("across"):sum()
    for _, child in ipairs(self.children) do
        if child:getSizing("across", self.direction) == "GROW" then
            child:setSize(acrossSize, "across", self.direction)
        end
    end

    for _, child in ipairs(self.children) do
        child:arrange(
            (child:getSize("along")),
            (child:getSize("across"))
        )
    end
end

--- Draws the UIElement and its children on the window.
--- @param window table
function UIElement:draw(window)
    LayoutManager.drawRectangle{window = window, position = Vector2(self.drawX, self.drawY), size = Vector2(self.width, self.height), color = self.backgroundColor}
    if self.children then
        for _, child in ipairs(self.children) do
            child:draw(window)
        end
    end
end

--- Calculates the layout position.
--- @param x number|nil
--- @param y number|nil
function UIElement:_setLayoutPositionRecursive(x, y)
    self.layoutX = x or self.layoutX
    self.layoutY = y or self.layoutY

    local offset = self:getPadding("along").x

    for _, child in ipairs(self.children) do
        if self.direction == "LEFT_TO_RIGHT" then
            child:_setLayoutPositionRecursive(
                self.layoutX + offset,
                self.layoutY + self.padding.top
            )
            offset = offset + child.width + self.childGap
        else
            child:_setLayoutPositionRecursive(
                self.layoutX + self.padding.left,
                self.layoutY + offset
            )
            offset = offset + child.height + self.childGap
        end
    end
end

--- Calculates the draw position.
--- @param x number|nil
--- @param y number|nil
function UIElement:_setDrawPositionRecursive(x, y)
    self.drawX = x or self.drawX
    self.drawY = y or self.drawY

    local offset = self:getPadding("along").x

    for _, child in ipairs(self.children) do
        if self.direction == "LEFT_TO_RIGHT" then
            child:_setDrawPositionRecursive(
                self.drawX + offset,
                self.drawY + self.padding.top
            )
            offset = offset + child.width + self.childGap
        else
            child:_setDrawPositionRecursive(
                self.drawX + self.padding.left,
                self.drawY + offset
            )
            offset = offset + child.height + self.childGap
        end
    end
end

--- Gets the sizing type of the UIElement based on side and direction.
--- @param side string
--- @param direction string|nil
--- @return string
function UIElement:getSizing(side, direction)
    direction = direction or self.direction

    if direction == "LEFT_TO_RIGHT" then
        if side == "along" then
            return self.widthSizing
        elseif side == "across" then
            return self.heightSizing
        else
            error("Invalid side.", 2)
        end
    elseif direction == "TOP_TO_BOTTOM" then
        if side == "along" then
            return self.heightSizing
        elseif side == "across" then
            return self.widthSizing
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Gets the growth factor of the UIElement based on side and direction.
--- @param side string
--- @param direction string|nil
--- @return string
function UIElement:getGrowthFactor(side, direction)
    direction = direction or self.direction

    if direction == "LEFT_TO_RIGHT" then
        if side == "along" then
            return self.widthGrow
        elseif side == "across" then
            return self.heightGrow
        else
            error("Invalid side.", 2)
        end
    elseif direction == "TOP_TO_BOTTOM" then
        if side == "along" then
            return self.heightGrow
        elseif side == "across" then
            return self.widthGrow
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Sets the size of the UIElement based on side and direction.
--- @param size number
--- @param side string
--- @param type string
--- @param direction string|nil
function UIElement:setSize(size, type, side, direction)
    direction = direction or self.direction
    size = math.floor(size)

    if direction == "LEFT_TO_RIGHT" then
        if side == "along" then
            if type == "min" then
                self.widthMinimum = size
            elseif type == "max" then
                self.widthMaximum = size
            elseif type == "size" then
                self.width = size
            else
                error("Invalid type.", 2)
            end
        elseif side == "across" then
            if type == "min" then
                self.heightMinimum = size
            elseif type == "max" then
                self.heightMaximum = size
            elseif type == "size" then
                self.height = size
            else
                error("Invalid type.", 2)
            end
        else
            error("Invalid side.", 2)
        end
    elseif direction == "TOP_TO_BOTTOM" then
        if side == "along" then
            if type == "min" then
                self.heightMinimum = size
            elseif type == "max" then
                self.heightMaximum = size
            elseif type == "size" then
                self.height = size
            else
                error("Invalid type.", 2)
            end
        elseif side == "across" then
            if type == "min" then
                self.widthMinimum = size
            elseif type == "max" then
                self.widthMaximum = size
            elseif type == "size" then
                self.width = size
            else
                error("Invalid type.", 2)
            end
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Gets the size and minimum size of the UIElement based on side and direction.
--- @param side string
--- @param direction string|nil
--- @return number
--- @return number
--- @return number
function UIElement:getSize(side, direction)
    direction = direction or self.direction

    if direction == "LEFT_TO_RIGHT" then
        if side == "along" then
            return self.width, self.widthMinimum, self.widthMaximum
        elseif side == "across" then
            return self.height, self.heightMinimum, self.heightMaximum
        else
            error("Invalid side.", 2)
        end
    elseif direction == "TOP_TO_BOTTOM" then
        if side == "along" then
            return self.height, self.heightMinimum, self.heightMaximum
        elseif side == "across" then
            return self.width, self.widthMinimum, self.widthMaximum
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Gets the padding of the UIElement based on side and direction.
--- @param side string
--- @param direction string|nil
--- @return table
function UIElement:getPadding(side, direction)
    direction = direction or self.direction

    if direction == "LEFT_TO_RIGHT" then
        if side == "along" then
            return Vector2(self.padding.left, self.padding.right)
        elseif side == "across" then
            return Vector2(self.padding.top, self.padding.bottom)
        else
            error("Invalid side.", 2)
        end
    elseif direction == "TOP_TO_BOTTOM" then
        if side == "along" then
            return Vector2(self.padding.top, self.padding.bottom)
        elseif side == "across" then
            return Vector2(self.padding.left, self.padding.right)
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

--- Returns whether the coordinates are within the UIElement.
function UIElement:contains(x, y)
    x = tonumber(x)
    y = tonumber(y)
    return x >= self.drawX
       and x < self.drawX + self.width
       and y >= self.drawY
       and y < self.drawY + self.height
end

--- Meant to be overridden by more complex elements.
function UIElement:handleEvent(event)
    for _, child in ipairs(self.children) do
        if child:handleEvent(event) then
            return true
        end
    end
end

--- Creates a new Label.
function Label:new(properties)
    UIElement.new(self, properties)

    LayoutManager.textElements[self] = true

    if properties.text ~= nil and type(properties.text) ~= "string" then
        error("Invalid text when creating new Label.", 3)
    end
    if properties.textColor ~= nil and type(properties.textColor) ~= "number" then
        error("Invalid textColor when creating new Label.", 3)
    end
    self.text = properties.text or ""
    self.textColor = properties.textColor or 1
end

--- Overrides the UIElement draw method.
function Label:draw(window)
    UIElement.draw(self, window)

    local x = self.drawX + self.padding.left
    local y = self.drawY + self.padding.top
    window.setTextColor(self.textColor)
    local lines = require "cc.strings".wrap(self.text, self.width)
    for i = 1, #lines do
        window.setCursorPos(x, y + i - 1)
        window.write(lines[i])
    end
end

-- Creates a new Button.
function Button:new(properties)
    Label.new(self, properties)

    LayoutManager.buttonElements[self] = true

    if properties.onClick == nil or type(properties.onClick) ~= "function" then
        error("Invalid onClick when creating new Button.", 3)
    end
    self.onClick = properties.onClick
    self.normalColor = properties.backgroundColor or 256
    if properties.pressedColor ~= nil and type(properties.pressedColor) ~= "number" then
        error("Invalid pressedColor when creating new Label.", 3)
    end
    self.pressedColor = properties.pressedColor or 128
    self.isPressed = false
end

--- Overrides the UIElement draw method.
function Button:draw(window)
    self.backgroundColor = self.isPressed
        and self.pressedColor
        or self.normalColor

    Label.draw(self, window)
end

--- Overrides the UIElement handleEvent method.
function Button:handleEvent(event)
    local name = event[1]
    if name == "mouse_click" or name == "monitor_touch" then
        local x, y = event[3], event[4]
        if self:contains(x, y) then
            self.isPressed = not self.isPressed
            if self.isPressed then self.onClick(self) end
            return true
        end
    end
    return UIElement.handleEvent(self, event)
end

--- Adds two Vector2s together.
--- @param vec1 table
--- @param vec2 table
--- @return table
Vector2.__add = function (vec1, vec2)
    local x = (vec1.x or vec1[1]) + (vec2.x or vec2[1])
    local y = (vec1.y or vec1[2]) + (vec2.y or vec2[2])
    return Vector2(x, y)
end

--- Instanciates a new Vector2.
--- @param x number
--- @param y number
function Vector2:new(x, y)
    self.x = x or 0
    self.y = y or 0
end

--- Gets the sum of the Vector2.
--- @return number
function Vector2:sum()
    return self.x + self.y
end

return LayoutManager
