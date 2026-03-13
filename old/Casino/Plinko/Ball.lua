local Ball = {}
Ball.__index = Ball

function Ball.new(x, y, color, foregroundColorMap, backgroundColorMap)
    local ball = setmetatable({}, Ball)

    ball.x = x or 0
    ball.y = y or 0
    ball.color = color or colors.black
    ball.foregroundColorMap = foregroundColorMap or {}
    ball.backgroundColorMap = backgroundColorMap or {}
    ball.prevPixels = {
        ["1:1"] = colors.black,
        ["1:2"] = colors.black,
        ["2:1"] = colors.black,
        ["2:2"] = colors.black,
    }

    return ball
end

function Ball:checkBelowBall(checkPinCollision)
    local result = {
        left_collided = checkPinCollision({x = self.x, y = self.y+2}),
        right_collided = checkPinCollision({x = self.x+1, y = self.y+2})
    }
    return result
end

function Ball:clear(monitor, fallbackColor)
    fallbackColor = fallbackColor or colors.black
    for x = 1, 2, 1 do
        local checkX = self.x + x - 1
        local backgroundColumns = self.backgroundColorMap[checkX]
        local foregroundColumns = self.foregroundColorMap[checkX]
        for y = 1, 2, 1 do
            local checkY  =self.y + y - 1
            monitor.setBackgroundColor(fallbackColor)
            if backgroundColumns ~= nil and backgroundColumns[checkY] ~= nil then
                monitor.setBackgroundColor(backgroundColumns[checkY]) end
            if foregroundColumns ~= nil and foregroundColumns[checkY] ~= nil then
                monitor.setBackgroundColor(foregroundColumns[checkY]) end

            monitor.setCursorPos(checkX, checkY)
            monitor.write(" ")
        end
    end
    self.isActive = false
end

function Ball:move(monitor, x, y, fallbackColor)
    self:clear(monitor, fallbackColor)
    self.x = self.x + x
    self.y = self.y + y
    self:displayOnScreen(monitor)
end

function Ball:displayOnScreen(monitor)
    monitor.setCursorPos(self.x,self.y)
    monitor.setBackgroundColor(self.color)
    for x = 1, 2, 1 do
        local checkX = self.x + x - 1
        local columns = self.foregroundColorMap[checkX]
        for y = 1, 2, 1 do
            local checkY = self.y + y - 1
            if columns ~= nil and columns[checkY] ~= nil then goto continue end
            monitor.setCursorPos(checkX, checkY)
            monitor.write(" ")
            ::continue::
        end
    end
    self.isActive = true
end

function Ball:click()
    if self.isActive then
        self.clickEvent()
    end
end

return Ball