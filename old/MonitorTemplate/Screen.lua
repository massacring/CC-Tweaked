local Button = require('Button')

local Screen = {
    monitor = nil,
    name = "Screen",
    buttonsRegistry = {},
    backgroundColor = colors.black,
}

function Screen:new(_o, name, monitor, backgroundColor)
    assert(type(monitor) == "table", "monitor must be a table.")
    local o = _o or {}
    setmetatable(o, self)
    self.__index = self
    o.name = name
    o.monitor = monitor
    o.width, o.height = monitor.getSize()
    o.backgroundColor = backgroundColor or colors.black
    o.buttonsRegistry = {}

    return o
end

function Screen:loadRainbow()
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

    for t = 1, 100, 1 do
        for i = 2, self.width-1, 1 do
            for j = 2, self.height-1, 1 do
                self.monitor.setCursorPos(i, j)
                self.monitor.setBackgroundColor(colorTable[(i+j+t) % #colorTable + 1])
                self.monitor.write(" ")
            end
        end
        sleep(0.05)
    end
end

function Screen:clearWindow(color)
    local monitor = self.monitor
    monitor.setTextScale(1)
    self.width, self.height = monitor.getSize()
    monitor.setBackgroundColor(color)
    monitor.clear()
    monitor.setCursorPos(1, 1)
end

function Screen:getCenter(x, y, x_content, y_content)
    local x_offset = math.floor(self.width  / 2) - math.floor(x_content / 2) + 1
    local y_offset = math.floor(self.height / 2) - math.floor(y_content / 2) + 1
    return x_offset + x, y_offset + y
end

function Screen:registerButton(button)
    assert(button.isButton, "You can only register buttons.")
    table.insert(self.buttonsRegistry, button)
end

function Screen:createButton(label, clickEvent, _x, _y, _height, labelPad, backgroundColorNormal, backgroundColorPressed, borderColorNormal, borderColorPressed, textColorNormal, textColorPressed, isCenter)
    assert(type(clickEvent) == "function", "clickEvent is not a function.")

    local x = _x or 0
    local y = _y or 0

    if isCenter then
        x, y = self:getCenter(x, y, (#label + 4), 5)
    end

    local button = Button:new(nil, self.monitor, clickEvent, x, y, #label, _height, label, labelPad, backgroundColorNormal, backgroundColorPressed, borderColorNormal, borderColorPressed, textColorNormal, textColorPressed)
    self:registerButton(button)
    return button
end

function Screen:placeButtons()
    for index, button in pairs(self.buttonsRegistry) do
        button:displayOnScreen()
    end
end

function Screen:loadScreen()
    self:clearWindow(self.backgroundColor)
    self:placeButtons()
end

return Screen