--- VARIABLES ---
local Commons = require("CasinoCommons")

local Ball = {}
local Button = {}

local monitor = peripheral.find("monitor")
local speaker = peripheral.find("speaker")

-- Declares my own colors
local m_colors = {
    white = colors.white,
    black = colors.black,
    gray = colors.gray,
    lightGray = colors.lightGray,
    orange = colors.orange,
    darkOrange = colors.magenta,
    yellow = colors.yellow,
    lightYellow = colors.lightBlue,
    lime = colors.lime,
    green = colors.green,
    red = colors.red,
    darkRed = colors.pink,
    darkGray = colors.brown,
    purple = colors.purple,
    darkGold = colors.cyan,
    lightGold = colors.blue
}

monitor.setBackgroundColor(m_colors.black)
monitor.clear()
local window = window.create(monitor, 1, 1, 80, 38)
local gameSpeed = 0.05
local maxBalls = 5
local width, height = window.getSize()
local defaultBackgroundColor = m_colors.lightGray
local defaultTextColor = m_colors.white
local pinColor = m_colors.white
local shadowColor = m_colors.gray
local ballColor = m_colors.darkGray
local scoreboardColor = m_colors.purple
local scoreboardTitleColor = m_colors.darkGray
local pinAreas = {}
local balls = {}
local cashoutButton = {}

local gameRunning = true

-- key (x) = value ({key (y) = value (color)})
local backgroundColorMap = {}
local foregroundColorMap = {}

local goals = {
    l_green = {startPos = 2, value = 33, primaryColor = m_colors.lime, secondaryColor = m_colors.green},
    l_lightYellow = {startPos = 8, value = 11, primaryColor = m_colors.lightYellow, secondaryColor = m_colors.yellow},
    l_yellow = {startPos = 14, value = 4, primaryColor = m_colors.yellow, secondaryColor = m_colors.lightYellow},
    l_orange = {startPos = 20, value = 2, primaryColor = m_colors.orange, secondaryColor = m_colors.darkOrange},
    l_darkOrange = {startPos = 26, value = 1.5, primaryColor = m_colors.darkOrange, secondaryColor = m_colors.orange},
    l_red = {startPos = 32, value = 0.6, primaryColor = m_colors.red, secondaryColor = m_colors.darkRed},
    c_darkRed = {startPos = 38, value = 0.3, primaryColor = m_colors.darkRed, secondaryColor = m_colors.red},
    r_red = {startPos = 44, value = 0.6, primaryColor = m_colors.red, secondaryColor = m_colors.darkRed},
    r_darkOrange = {startPos = 50, value = 1.5, primaryColor = m_colors.darkOrange, secondaryColor = m_colors.orange},
    r_orange = {startPos = 56, value = 2, primaryColor = m_colors.orange, secondaryColor = m_colors.darkOrange},
    r_yellow = {startPos = 62, value = 4, primaryColor = m_colors.yellow, secondaryColor = m_colors.lightYellow},
    r_lightYellow = {startPos = 68, value = 11, primaryColor = m_colors.lightYellow, secondaryColor = m_colors.yellow},
    r_green = {startPos = 74, value = 33, primaryColor = m_colors.lime, secondaryColor = m_colors.green},
}

local function clear()
    window.setBackgroundColor(defaultBackgroundColor)
    window.setTextColor(defaultTextColor)
    window.clear()
    window.setCursorPos(1,1)
end

-- Changes the default palette
local function setPalatte()
    window.setPaletteColor(colors.orange, 0xDD9D54) -- new orange
    window.setPaletteColor(colors.magenta, 0xD98752) -- secondare orange
    window.setPaletteColor(colors.yellow, 0xECDC5B) -- new yellow
    window.setPaletteColor(colors.lightBlue, 0xE3EA5B) -- secondary yellow
    window.setPaletteColor(colors.lime, 0xA0CA55) -- new lime
    window.setPaletteColor(colors.pink, 0xB73535) -- secondary red
    window.setPaletteColor(colors.brown, 0x4C4C4C) -- dark (old) gray
    window.setPaletteColor(colors.gray, 0x727272) -- new gray
    window.setPaletteColor(colors.cyan, 0xE1B156) -- dark gold
    window.setPaletteColor(colors.blue, 0xE8C958) -- light gold
end

local function drawDot(x,y,color, isForeground)
    window.setCursorPos(x,y)
    window.setBackgroundColor(color)
    window.write(" ")
    if isForeground then
        foregroundColorMap[x] = foregroundColorMap[x] or {}
        foregroundColorMap[x][y] = color
    else
        backgroundColorMap[x] = backgroundColorMap[x] or {}
        backgroundColorMap[x][y] = color
    end
    
end

local function drawSquare(x, y, span, length, color, isForeground)
    window.setCursorPos(x,y)
    window.setBackgroundColor(color)
    for row = 1, length, 1 do
        window.setCursorPos(x,y+row-1)
        window.write(string.rep(" ", span))
        for column = 1, span, 1 do
            local storeX = x+column-1
            local storeY = y+row-1
            if isForeground then
                foregroundColorMap[storeX] = foregroundColorMap[storeX] or {}
                foregroundColorMap[storeX][storeY] = color
            else
                backgroundColorMap[storeX] = backgroundColorMap[storeX] or {}
                backgroundColorMap[storeX][storeY] = color
            end
        end
    end
end

local function write(text, x, y, textColor, backGroundColor, isForeground)
    backGroundColor = backGroundColor or defaultBackgroundColor
    textColor = textColor or defaultTextColor
    window.setCursorPos(x,y)
    window.setBackgroundColor(backGroundColor)
    window.setTextColor(textColor)
    window.write(text)
    for column = 1, string.len(text), 1 do
        local storeX = x+column-1
        if isForeground then
            foregroundColorMap[storeX] = foregroundColorMap[storeX] or {}
            foregroundColorMap[storeX][y] = backGroundColor
        else
            backgroundColorMap[storeX] = backgroundColorMap[storeX] or {}
            backgroundColorMap[storeX][y] = backGroundColor
        end
    end
end

local function generatePin(x, y)
    local area = {}
    for column = 1, 2, 1 do
        table.insert(area, {x = x+column, y = y})
    end
    table.insert(pinAreas, area)
end

local function generateAllPins()
    local midPoint = width / 2

    for row = 1,34,3 do
        if row == 1 then goto continue end
        for column = 1,(row/3)+1,1 do
            local x = (midPoint - (row - 1) + (column*6) - 6) - 1
            local y = row - 2
            generatePin(x, y)
        end
        ::continue::
    end
end

local function drawAllPins()
    for _, area in pairs(pinAreas) do
        for _, coord in pairs(area) do
            drawDot(coord.x+1, coord.y+1, shadowColor)
            drawDot(coord.x+1, coord.y+2, shadowColor)
            drawDot(coord.x, coord.y, pinColor, true)
            drawDot(coord.x, coord.y+1, pinColor, true)
        end
    end
end

local function drawGoal(x, y, text, primaryColor, secondaryColor, textColor)
    drawSquare(x, y, 6, 3, primaryColor, true)
    drawSquare(x+1, y+1, 4, 1, secondaryColor, true)
    window.setCursorPos(x+1, y+1)
    window.setTextColor(textColor)
    window.write(text)
end

local function drawAllGoals()
    local y = height-3
    local textColor = m_colors.darkGray
    for _, goal in pairs(goals) do
        local text = tostring(goal.value)
        drawGoal(goal.startPos, y, " "..text, goal.primaryColor, goal.secondaryColor, textColor)
    end
end

local function drawScoreboard()
    local scoreTitle = "Score:"
    local scoreText = tostring(Commons.Score:getScore())
    local scoreTextLen = string.len(scoreText) + 2
    if scoreTextLen < 9 then scoreTextLen = 9 end
    local startX = width - 2 - scoreTextLen

    window.setTextColor(m_colors.white)
    drawSquare(startX+1, 4, scoreTextLen, 3, shadowColor)
    drawSquare(startX, 3, scoreTextLen, 3, scoreboardColor, true)
    window.setCursorPos(startX+1, 4)
    window.write(scoreText)
    drawSquare(startX+1, 2, 6, 1, scoreboardTitleColor, true)
    window.setCursorPos(startX+1, 2)
    window.write(scoreTitle)
end

local function debugColorMaps()
    clear()
    for column, rows in pairs(backgroundColorMap) do
        for row, _ in pairs(rows) do
            window.setCursorPos(column,row)
            window.setBackgroundColor(m_colors.lime)
            window.write(" ")
        end
    end
    for column, rows in pairs(foregroundColorMap) do
        for row, _ in pairs(rows) do
            window.setCursorPos(column,row)
            window.setBackgroundColor(m_colors.purple)
            window.write(" ")
        end
    end
end

local function drawScreen()
    clear()
    drawAllPins()
    drawAllGoals()
    drawScoreboard()
    drawSquare(cashoutButton.x+1, cashoutButton.y+1, cashoutButton.width, cashoutButton.height, shadowColor)
    cashoutButton:displayOnScreen(drawSquare, write)
    --debugColorMaps()
end

local function spawnBall()
    local ball = Ball.new(math.random(37, 45), 0, ballColor, foregroundColorMap, backgroundColorMap)
    table.insert(balls, ball)
end

local function endRun()
    clear()
    gameRunning = false
end

local function createCashoutButton()
    local label = "Cash out!"
    local labelLength = string.len(label)
    local x = width - labelLength - 3
    local y = 8
    local span = labelLength
    local length = 1
    local labelPad = 0
    local backgroundColorNormal = m_colors.darkGold
    local borderColorNormal = m_colors.orange
    local textColorNormal = m_colors.white
    cashoutButton = Button.new(label, endRun, x, y, span, length, labelPad, backgroundColorNormal, borderColorNormal, textColorNormal)
end

local function init()
    monitor.setTextScale(0.5)
    setPalatte()
    generateAllPins()
    createCashoutButton()
    drawScreen()
end

-- Returns "right" around one in 'i' times, otherwise returns "left".
local function calculateStep(i)
    return (math.random(i) % i == 0) and "right" or "left"
end

local function checkPinCollision(coord)
    coord.x = coord.x or 0
    coord.y = coord.y or 0
    for _, area in pairs(pinAreas) do
        for _, pinCoord in pairs(area) do
            local result = coord.x == pinCoord.x and coord.y == pinCoord.y
            if result then return true end
        end
    end
    return false
end

local function moveHorizontally(ball, direction, velocity)
    local directionalVelocity = ((direction == "right") and 1 or -1)
    for i = 1,velocity,1 do
        ball:move(window, 1 * directionalVelocity, 0, defaultBackgroundColor)
        local result = ball:checkBelowBall(checkPinCollision)
        if not (result.left_collided or result.right_collided) and i ~= 1 then
            ball:move(window, 0, 1, defaultBackgroundColor)
        end
        if i == velocity then return end
        sleep(gameSpeed)
    end
end

local function calculateGoalPos(ball)
    local x = ball.x
    local midPoint = width / 2
    local difference = midPoint - x
    local result

    if (difference >= 0 and difference < 2)
    or (difference <= 0 and difference > -3) then
        return "c_darkRed"
    elseif (difference > 0 and difference < 8)
    or (difference < 0 and difference > -9) then
        result = ((difference > 0) and "l_" or "r_") .. "red"
    elseif (difference > 0 and difference < 14)
    or (difference < 0 and difference > -15) then
        result = ((difference > 0) and "l_" or "r_") .. "darkOrange"
    elseif (difference > 0 and difference < 20)
    or (difference < 0 and difference > -21) then
        result = ((difference > 0) and "l_" or "r_") .. "orange"
    elseif (difference > 0 and difference < 26)
    or (difference < 0 and difference > -27) then
        result = ((difference > 0) and "l_" or "r_") .. "yellow"
    elseif (difference > 0 and difference < 32)
    or (difference < 0 and difference > -33) then
        result = ((difference > 0) and "l_" or "r_") .. "lightYellow"
    else
        result = ((difference > 0) and "l_" or "r_") .. "green"
    end
    return result
end

local function calculateReward(ball)
    local goal = calculateGoalPos(ball)
    local multiplier = goals[goal].value
    Commons.Score:updateScore(math.ceil(Commons.Score:getScore() * multiplier))
    drawScoreboard()
end

local function countBalls()
    local count = 0
    for _, ball in pairs(balls) do
        if ball ~= nil then count = count + 1 end
    end
    return count
end

local function playPinDing(direction)
    local leftPitches = {0, 12, 24}
    local rightPitches = {6, 18}
    local pitch = (direction == "right") and rightPitches[math.random(#rightPitches)] or leftPitches[math.random(#leftPitches)]
    speaker.playNote("pling", 1, pitch)
end

local function playEndDing()
    speaker.playNote("pling", 1, 10)
    sleep(0.05)
    speaker.playNote("pling", 1, 11)
    sleep(0.05)
    speaker.playNote("pling", 1, 13)
end

local function tick()
    while gameRunning do
        for _, ball in pairs(balls) do
            local result = ball:checkBelowBall(checkPinCollision)
            if result.left_collided or result.right_collided then
                if result.left_collided and result.right_collided then
                    local direction = calculateStep(2)
                    local velocity = math.random(2, 4)
                    moveHorizontally(ball, direction, velocity)
                    playPinDing(direction)
                else
                    local direction = result.left_collided and "right" or "left"
                    local velocity = math.random(3)
                    moveHorizontally(ball, direction, velocity)
                    playPinDing(direction)
                end
            else
                ball:move(window, 0, 1, defaultBackgroundColor)
            end
                if ball.y >= height-3 then
                ball:move(window, 0, -1, defaultBackgroundColor)
                calculateReward(ball)
                ball:clear(window, defaultBackgroundColor)
                balls[_] = nil
                drawAllGoals()
                playEndDing()
            end
        end
        sleep(gameSpeed)
    end
end

local function events()
    sleep(0.5)
    while gameRunning do
        local eventData = {os.pullEvent()}
        local event = eventData[1]
        if event == "key_up" and eventData[2] == keys.q then
            return
        elseif event == "monitor_touch" then
            local x, y = eventData[3], eventData[4]
            if cashoutButton:collides(x, y) then
                cashoutButton.clickEvent()
                return
            else
                local ballCount = countBalls()
                if Commons.Score:getScore() * (0.3 ^ (ballCount+1)) < 1.0
                then print("Out of coin!")
                elseif (ballCount >= maxBalls)
                then print("Too many balls!")
                else spawnBall() end
            end
            sleep(0.1)
        end
    end
end

local function runGame()
    parallel.waitForAny(tick, events)
end

--- BALL ---

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

--- BUTTON ---

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

function Button:displayOnScreen(drawSquare, write)
    local x_offset, y_offset = self.labelPad, self.labelPad

    if self.borderColor then
        x_offset = x_offset + 1
        y_offset = y_offset + 1
        drawSquare(self.x, self.y, self.width, self.height, self.borderColor, true)
    end

    drawSquare(self.x+1, self.y+1, self.width-2, self.height-2, self.backgroundColorCurrent, true)

    write(self.label, self.x + x_offset, self.y + y_offset, self.textColorCurrent, self.backgroundColorCurrent, true)

    self.isActive = true
end

function Button:collides(x, y)
    return ((x >= self.x) and (x < (self.x + self.width))) and ((y >= self.y) and (y < (self.y + self.height)))
end

--- RETURN ---

return { init = init, drawScreen = drawScreen, runGame = runGame, Button = Button, Ball = Ball }
