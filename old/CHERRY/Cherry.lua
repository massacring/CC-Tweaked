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
--]]

---Main Object Class
local Cherry = {}
Cherry.__index = Cherry

---Creates a new Object
function Cherry:new()
end

---Returns an object that extends this one.
---@return table
function Cherry:extend()
    local cherry = {}
    for key, value in pairs(self) do
        if key:find("__") == true then
            cherry[key] = value
        end
    end
    cherry.__index = cherry
    cherry.super = self
    setmetatable(cherry, self)
    return cherry
end

---Implements the functions of objects.
---@param ... table
function Cherry:implement(...)
  for _, cherry in pairs({...}) do
    for key, value in pairs(cherry) do
      if self[key] == nil and type(value) == "function" then
        self[key] = value
      end
    end
  end
end

---Overrides the call functionality of the Object to return a new instance of the Object.
---@param ... unknown
---@return table
function Cherry:__call(...)
    local cherry = setmetatable({}, self)
---@diagnostic disable-next-line: redundant-parameter
    cherry:new(...)
    return cherry
end

local UIElement = Cherry:extend()
local Vector2 = Cherry:extend()

---Returns a function that determines the element width and size to FIT.
---@return function
local function fit()
    return function (element, type)
        if type == "width" then
            element.widthSizing = "FIT"
            element.width = 0
        else
            element.heightSizing = "FIT"
            element.height = 0
        end
    end
end


---Returns a function that determines the element width and size to FIXED.
---@param num number
---@return function
local function fixed(num)
    return function (element, type)
        if type == "width" then
            element.widthSizing = "FIXED"
            element.width = num
            element.widthMinimum = num
        else
            element.heightSizing = "FIXED"
            element.height = num
            element.heightMinimum = num
        end
    end
end

---Returns a function that determines the element width and size to GROW.
---@return function
local function grow()
    return function (element, type)
        if type == "width" then
            element.widthSizing = "GROW"
            element.width = 0
        else
            element.heightSizing = "GROW"
            element.height = 0
        end
        return 0
    end
end

---Draws a rectangle.
---@param properties table
local function drawRectangle(properties)
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

---Creates a new UIElement Object
---@param properties table
function UIElement:new(properties)
    setmetatable(properties, {__index={
        direction = "LEFT_TO_RIGHT",
        position = { 0, 0 },
        size = { fit(), fit() },
        padding = { left = 0, top = 0, right = 0, bottom = 0 },
        childGap = 0,
        children = {},
        backgroundColor = 1
    }})

    self.parent = properties.parent

    self.direction = properties.direction
    local x, y =
        properties.position.x or properties.position[1],
        properties.position.y or properties.position[2]
    self.position = Vector2(x, y)
    self.x = x
    self.y = y
    properties.size[1](self, "width")
    properties.size[2](self, "height")
    self.size = Vector2(self.width, self.height)
    self.padding = properties.padding
    self.childGap = properties.childGap
    self.backgroundColor = properties.backgroundColor
    self.children = {}

    if properties.text ~= nil then
        self.text = properties.text
        self.isText = true
        self.preferredWidth = #properties.text

        for word in string.gmatch(self.text, " ") do
            local length = #word
            if length > self.widthMinimum then
                self.widthMinimum = length
                self.width = length
            end
        end
    end

    for _, child in ipairs(properties.children) do
        -- Do something
        child.parent = self
        table.insert(self.children, UIElement(child))
    end

    self:fitSizing()
    self:growAndShrinkChildElements()
    self:calculateChildPositions()
end

---Calculates the child positions of the UIElement.
function UIElement:calculateChildPositions()
    local offset = self:getPadding("along").x
    if self.children then
        for _, child in ipairs(self.children) do
            local childPos = Vector2(child.x, child.y)
            childPos = childPos + Vector2(self.x, self.y)

            if self.direction == "LEFT_TO_RIGHT" then
                child.x = childPos.x + offset
                child.y = childPos.y + self.padding.top
                offset = offset + child.width + self.childGap
            elseif self.direction == "TOP_TO_BOTTOM" then
                child.y = childPos.y + offset
                child.x = childPos.x + self.padding.left
                offset = offset + child.height + self.childGap
            else
                error("Invalid direction.", 2)
            end
        end
    end
end

---Grows and Shrinks the child elements of the UIelement.
function UIElement:growAndShrinkChildElements()
    local remainingAlong = self:getSize("along")
    remainingAlong = remainingAlong - self:getPadding("along"):sum()

    for _, child in ipairs(self.children) do
        remainingAlong = remainingAlong - child:getSize("along", self.direction)
    end
    remainingAlong = remainingAlong - (#self.children - 1) * self.childGap

    local growable = {}

    for _, child in ipairs(self.children) do
        if child:getSizing("along", self.direction) == "GROW" then table.insert(growable, child) end
        if child:getSizing("across", self.direction) == "GROW" then
            child:setSize(self:getSize("across") - self:getPadding("across"):sum(), "across", self.direction)
        end
    end

    if #growable == 0 then return end

    while remainingAlong > 0 do
        local smallest = growable[1]:getSize("along")
        local secondSmallest = 2147483647 -- max integer
        local sizeToAdd = remainingAlong

        for _, child in ipairs(growable) do
            if child:getSize("along") < smallest then
                secondSmallest = smallest
                smallest = child:getSize("along")
            end
            if child:getSize("along") > smallest then
                secondSmallest = math.min(secondSmallest, child:getSize("along"))
                sizeToAdd = secondSmallest - smallest
            end
        end

        sizeToAdd = math.min(sizeToAdd, math.floor(remainingAlong / #growable))
        if sizeToAdd == 0 then
            sizeToAdd = 1
        end

        for _, child in ipairs(growable) do
            if child:getSize("along") == smallest then
                child:addSize(sizeToAdd, "along", self.direction)
                remainingAlong = remainingAlong - sizeToAdd
                if remainingAlong <= 0 then
                    break
                end
            end
        end
    end
end

---Fits the size of the UIElement to its children.
function UIElement:fitSizing()
    local parent = self.parent
    if self:getSizing("along") == "FIT" then
        self:addSize(self:getPadding("along"):sum(), "along")
    end
    if self:getSizing("across") == "FIT" then
        self:addSize(self:getPadding("across"):sum(), "across")
    end

    if not self.parent then return end

    local childGap = (math.max(0, #self.children - 1) * self.childGap)
    if parent:getSizing("along") == "FIT" then
        parent:addSize(self:getSize("along", parent.direction) + childGap, "along")
    end
    if parent:getSizing("across") == "FIT" then
        parent:setSize(math.max(self:getSize("across", parent.direction), parent:getSize("across")), "across")
    end
end

---Gets the sizing type of the UIElement based on side and direction.
---@param side string
---@param direction string
---@return string
function UIElement:getSizing(side, direction)
    if direction == nil then
        direction = self.direction
    end

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

---Sets the size of the UIElement based on side and direction.
---@param size number
---@param side string
---@param direction string
function UIElement:setSize(size, side, direction)
    if direction == nil then
        direction = self.direction
    end

    if direction == "LEFT_TO_RIGHT" then
        if side == "along" then
            self.width = size
        elseif side == "across" then
            self.height = size
        else
            error("Invalid side.", 2)
        end
    elseif direction == "TOP_TO_BOTTOM" then
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

---Adds to the size of the UIElement based on side and direction.
---@param size number
---@param side string
---@param direction string
function UIElement:addSize(size, side, direction)
    if direction == nil then
        direction = self.direction
    end

    if direction == "LEFT_TO_RIGHT" then
        if side == "along" then
            self.width = self.width + size
        elseif side == "across" then
            self.height = self.height + size
        else
            error("Invalid side.", 2)
        end
    elseif direction == "TOP_TO_BOTTOM" then
        if side == "along" then
            self.height = self.height + size
        elseif side == "across" then
            self.width = self.width + size
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

---Removes from the size of the UIElement based on side and direction.
---@param size number
---@param side string
---@param direction string
function UIElement:removeSize(size, side, direction)
    if direction == nil then
        direction = self.direction
    end

    if direction == "LEFT_TO_RIGHT" then
        if side == "along" then
            self.width = self.width - size
        elseif side == "across" then
            self.height = self.height - size
        else
            error("Invalid side.", 2)
        end
    elseif direction == "TOP_TO_BOTTOM" then
        if side == "along" then
            self.height = self.height - size
        elseif side == "across" then
            self.width = self.width - size
        else
            error("Invalid side.", 2)
        end
    else
        error("Invalid direction.", 3)
    end
end

---Gets the size of the UIElement based on side and direction.
---@param side string
---@param direction string
---@return number
function UIElement:getSize(side, direction)
    if direction == nil then
        direction = self.direction
    end

    if direction == "LEFT_TO_RIGHT" then
        if side == "along" then
            return self.width
        elseif side == "across" then
            return self.height
        else
            error("Invalid side.", 2)
        end
    elseif direction == "TOP_TO_BOTTOM" then
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

---Gets the padding of the UIElement based on side and direction.
---@param side string
---@param direction string
---@return table
function UIElement:getPadding(side, direction)
    if direction == nil then
        direction = self.direction
    end

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

---Draws the UIElement and its children on the window.
---@param window table
function UIElement:draw(window)
    drawRectangle{window = window, position = Vector2(self.x, self.y), size = Vector2(self.width, self.height), color = self.backgroundColor}
    if self.children then
        for _, child in ipairs(self.children) do
            drawRectangle{
                window = window,
                position = Vector2(child.x, child.y),
                size = Vector2(child.width, child.height),
                color = child.backgroundColor
            }
        end
    end
end

---Adds two Vector2s together.
---@param vec1 table
---@param vec2 table
---@return table
Vector2.__add = function (vec1, vec2)
    local x = vec1.x + vec2.x or vec1[1] + vec2[1]
    local y = vec1.y + vec2.y or vec1[2] + vec2[2]
    return Vector2(x, y)
end

---Instanciates a new Vector2.
---@param x number
---@param y number
function Vector2:new(x, y)
    self.x = x or 0
    self.y = y or 0
end

---Gets the sum of the Vector2.
---@return number
function Vector2:sum()
    return self.x + self.y
end

return { CHERRY = UIElement, FIXED = fixed, GROW = grow, FIT = fit }
