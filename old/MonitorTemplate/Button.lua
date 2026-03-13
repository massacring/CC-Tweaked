local Button = {
    isButton = true,
    isActive = false,
    monitor = nil,
    clickEvent = function() print("Click!") end,
    x = 1,
    y = 1,
    width = 7,
    height = 3,
    isPressed = false,
    backgroundColorCurrent = colors.black,
    backgroundColorNormal = colors.black,
    backgroundColorPressed = colors.gray,
    hasBorder = false,
    borderColorCurrent = nil,
    borderColorNormal = nil,
    borderColorPressed = nil,
    label = "Press",
    labelPad = 0,
    textColorCurrent = colors.lightGray,
    textColorNormal = colors.lightGray,
    textColorPressed = colors.white
}

function Button:new(_o, monitor, clickEvent, x, y, width, height, label, labelPad, backgroundColorNormal, backgroundColorPressed, borderColorNormal, borderColorPressed, textColorNormal, textColorPressed)
    assert(type(monitor) == "table", "display must be a table.")
    local o = _o or {}
    setmetatable(o, self)
    self.__index = self
    o.isButton = true
    o.isActive = false
    o.monitor = monitor
    o.clickEvent = clickEvent or function() print("Click!") end
    o.x = x or 1
    o.y = y or 1
    o.width = width or 3
    o.height = height or 3
    o.isPressed = false
    o.backgroundColorCurrent = backgroundColorNormal or colors.black
    o.backgroundColorNormal = backgroundColorNormal or colors.black
    o.backgroundColorPressed = backgroundColorPressed or colors.gray
    o.hasBorder = borderColorNormal and borderColorPressed
    if (label == "Rainbow") then o.hasBorder = false end
    if o.hasBorder then
        o.borderColorCurrent = borderColorNormal
        o.borderColorNormal = borderColorNormal
        o.borderColorPressed = borderColorPressed
    else
        o.borderColorCurrent = nil
        o.borderColorNormal = nil
        o.borderColorPressed = nil
    end
    o.label = label or "Press"
    o.labelPad = labelPad or 0
    o.textColorCurrent = textColorNormal or colors.lightGray
    o.textColorNormal = textColorNormal or colors.lightGray
    o.textColorPressed = textColorPressed or colors.white

    o.width = o.width + (o.labelPad * 2)
    o.height = o.height + (o.labelPad * 2)
    if o.hasBorder then
        o.width = o.width + 2
        o.height = o.height + 2
    end

    return o
end

local function loadRainbowButton(button, x_offset, y_offset)
    local monitor = button.monitor
    local colorTable = {
        colors.red;
        colors.orange;
        colors.yellow;
        colors.lime;
        colors.cyan;
        colors.blue;
        colors.magenta;
        colors.purple;
    }

    for i = 0, button.width-1, 1 do
        for j = 0, button.height-1, 1 do
            monitor.setCursorPos(button.x + i, button.y + j)
            monitor.setBackgroundColor(colorTable[(i+j) % #colorTable + 1])
            monitor.write(" ")
        end
    end

    local function split(str)
        if #str>0 then return str:sub(1,1),split(str:sub(2)) end
    end

    local labelChars={split(button.label)}
    monitor.setCursorPos(
        button.x + x_offset,
        button.y + y_offset
    )
    for i, char in pairs(labelChars) do
        monitor.setTextColor(colorTable[(i+y_offset + 5) % #colorTable + 1])
        monitor.setBackgroundColor(colorTable[(i+y_offset) % #colorTable + 1])
        monitor.write(char)
    end

    button.isActive = true
end

function Button:displayOnScreen()
    local x_offset, y_offset = self.labelPad, self.labelPad
    if self.label == "Rainbow" then 
        loadRainbowButton(self, x_offset, y_offset)
        return
    end

    local monitor = self.monitor
    monitor.setBackgroundColor(self.backgroundColorCurrent)
    for i = 0, self.height-1, 1 do
        monitor.setCursorPos(self.x, self.y + i)
        monitor.write(string.rep(" ", self.width))
    end

    if self.hasBorder then
        x_offset = x_offset + 1
        y_offset = y_offset + 1
        monitor.setBackgroundColor(self.borderColorCurrent)
        for i = 1, self.width, 1 do
            for j = 1, self.height, 1 do
                if not ((i == 1 or j == 1) or (i == self.width or j == self.height)) then goto continue end

                monitor.setCursorPos(self.x + (i-1), self.y + (j-1))
                monitor.write(" ")

                ::continue::
            end
        end
        monitor.setBackgroundColor(self.backgroundColorCurrent)
    end

    monitor.setCursorPos(
        self.x + x_offset,
        self.y + y_offset
    )
    monitor.setTextColor(self.textColorCurrent)
    monitor.write(self.label)
    self.isActive = true
end

function Button:clear(color)
    local monitor = self.monitor
    monitor.setBackgroundColor(color)
    for i = 0, self.height-1, 1 do
        monitor.setCursorPos(self.x, self.y + i)
        monitor.write(string.rep(" ", self.width))
    end
    self.isActive = false
end

function Button:move(x, y, color)
    self:clear(color or colors.black)
    self.x = x
    self.y = y
    self:displayOnScreen()
end

function Button:toggle()
    self.isPressed = not self.isPressed
    if self.isPressed then
        self.backgroundColorCurrent = self.backgroundColorPressed
        self.borderColorCurrent = self.borderColorPressed
        self.textColorCurrent = self.textColorPressed
    else
        self.backgroundColorCurrent = self.backgroundColorNormal
        self.borderColorCurrent = self.borderColorNormal
        self.textColorCurrent = self.textColorNormal
    end
    self:displayOnScreen()
end

return Button
