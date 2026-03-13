local Button = {}
Button.__index = Button

function Button.new(label, clickEvent, x, y, width, height, labelPad, backgroundColorNormal, borderColor, textColorNormal)
    local button = setmetatable({}, Button)
    button.isActive = false
    button.clickEvent = clickEvent or function() print("Click!") end
    button.x = x or 1
    button.y = y or 1
    button.width = width or 3
    button.height = height or 3
    button.isPressed = false
    button.backgroundColorCurrent = backgroundColorNormal or colors.black
    button.backgroundColorNormal = backgroundColorNormal or colors.black
    button.borderColor = borderColor
    button.label = label or "Press"
    button.labelPad = labelPad or 0
    button.textColorCurrent = textColorNormal or colors.lightGray
    button.textColorNormal = textColorNormal or colors.lightGray

    button.width = button.width + (button.labelPad * 2)
    button.height = button.height + (button.labelPad * 2)
    if button.borderColor then
        button.width = button.width + 2
        button.height = button.height + 2
    end

    return button
end

function Button:displayOnScreen(window, drawSquare, write)
    local x_offset, y_offset = self.labelPad, self.labelPad

    if self.borderColor then
        x_offset = x_offset + 1
        y_offset = y_offset + 1
        drawSquare(window, self.x, self.y, self.width, self.height, self.borderColor)
    end

    drawSquare(window, self.x+1, self.y+1, self.width-2, self.height-2, self.backgroundColorCurrent)

    write(window, self.label, self.x + x_offset, self.y + y_offset, self.textColorCurrent, self.backgroundColorCurrent)

    self.isActive = true
end

function Button:disable()
    self.isActive = false
end

function Button:collides(x, y)
    return ((x >= self.x) and (x < (self.x + self.width))) and ((y >= self.y) and (y < (self.y + self.height))) and self.isActive
end

return Button
