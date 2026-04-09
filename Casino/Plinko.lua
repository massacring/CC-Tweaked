--- VARIABLES ---
local Commons = require("CasinoCommons")

-- Declares my own colours
local m_colours = {
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

local colours = {
    creditTextColour = m_colours.white,
    creditBackgroundColour = m_colours.red,
    scoreTitleTextColour = m_colours.white,
    scoreTitleBackgroundColour = m_colours.darkGray,
    scoreValueTextColour = m_colours.white,
    scoreValueBackgroundColour = m_colours.purple
}

local maxBalls = 3
local defaultBackgroundColour = m_colours.lightGray
local defaultTextColour = m_colours.white
local pinColour = m_colours.white
local shadowColour = m_colours.gray
local ballColour = m_colours.darkGray
local pinAreas = {}
local balls = {}
local cashoutButton = {}
local startButton = {}

-- key (x) = value ({key (y) = value (colour)})
local backgroundColourMap = {}
local foregroundColourMap = {}

local goals = {
    l_green = {startPos = 2, value = 33, primaryColour = m_colours.lime, secondaryColour = m_colours.green},
    l_lightYellow = {startPos = 8, value = 11, primaryColour = m_colours.lightYellow, secondaryColour = m_colours.yellow},
    l_yellow = {startPos = 14, value = 4, primaryColour = m_colours.yellow, secondaryColour = m_colours.lightYellow},
    l_orange = {startPos = 20, value = 2, primaryColour = m_colours.orange, secondaryColour = m_colours.darkOrange},
    l_darkOrange = {startPos = 26, value = 1.5, primaryColour = m_colours.darkOrange, secondaryColour = m_colours.orange},
    l_red = {startPos = 32, value = 0.6, primaryColour = m_colours.red, secondaryColour = m_colours.darkRed},
    c_darkRed = {startPos = 38, value = 0.3, primaryColour = m_colours.darkRed, secondaryColour = m_colours.red},
    r_red = {startPos = 44, value = 0.6, primaryColour = m_colours.red, secondaryColour = m_colours.darkRed},
    r_darkOrange = {startPos = 50, value = 1.5, primaryColour = m_colours.darkOrange, secondaryColour = m_colours.orange},
    r_orange = {startPos = 56, value = 2, primaryColour = m_colours.orange, secondaryColour = m_colours.darkOrange},
    r_yellow = {startPos = 62, value = 4, primaryColour = m_colours.yellow, secondaryColour = m_colours.lightYellow},
    r_lightYellow = {startPos = 68, value = 11, primaryColour = m_colours.lightYellow, secondaryColour = m_colours.yellow},
    r_green = {startPos = 74, value = 33, primaryColour = m_colours.lime, secondaryColour = m_colours.green},
}

local EndGame
local StartGame

--- Plays the pin ding sound.
--- @param speaker table Represents the speaker to play the sound with.
local function playPinDing(speaker, direction)
    local leftPitches = {0, 12, 24}
    local rightPitches = {6, 18}
    local pitch = (direction == "right") and rightPitches[math.random(#rightPitches)] or leftPitches[math.random(#leftPitches)]
    speaker.playNote("pling", 1, pitch)
end

--- Plays the end ding sound.
--- @param speaker table Represents the speaker to play the sound with.
local function playEndDing(speaker)
    speaker.playNote("pling", 1, 10)
    sleep(0.05)
    speaker.playNote("pling", 1, 11)
    sleep(0.05)
    speaker.playNote("pling", 1, 13)
end

--- Changes the default palette
--- @param screen table Represents the screen to draw on.
local function setPalette(screen)
    screen.setPaletteColour(colors.orange, 0xDD9D54) -- new orange
    screen.setPaletteColour(colors.magenta, 0xD98752) -- secondare orange
    screen.setPaletteColour(colors.yellow, 0xECDC5B) -- new yellow
    screen.setPaletteColour(colors.lightBlue, 0xE3EA5B) -- secondary yellow
    screen.setPaletteColour(colors.lime, 0xA0CA55) -- new lime
    screen.setPaletteColour(colors.pink, 0xB73535) -- secondary red
    screen.setPaletteColour(colors.brown, 0x4C4C4C) -- dark (old) gray
    screen.setPaletteColour(colors.gray, 0x727272) -- new gray
    screen.setPaletteColour(colors.cyan, 0xE1B156) -- dark gold
    screen.setPaletteColour(colors.blue, 0xE8C958) -- light gold
end

--- Sets the background of the game.
--- @param screen table Represents the screen to draw on.
local function setBackground(screen)
    local oldTerm = term.redirect(screen)
    term.setBackgroundColour(defaultBackgroundColour)
    term.setTextColour(defaultTextColour)
    term.clear()
    term.setCursorPos(1,1)
    term.redirect(oldTerm)
end

--- Draws a dot to the screen and updates the relative colour map.
--- @param screen table Represents the screen to draw on.
--- @param x number Represents the X coordinate to start drawing at.
--- @param y number Represents the Y coordinate to start drawing at.
--- @param colour number Represents the colour of the dot.
--- @param isForeground boolean|nil Whether the dot is in the foreground or background.
local function drawDot(screen, x, y, colour, isForeground)
    local oldTerm = term.redirect(screen)
    term.setCursorPos(x,y)
    term.setBackgroundColour(colour)
    term.write(" ")
    if isForeground then
        foregroundColourMap[x] = foregroundColourMap[x] or {}
        foregroundColourMap[x][y] = colour
    else
        backgroundColourMap[x] = backgroundColourMap[x] or {}
        backgroundColourMap[x][y] = colour
    end
    term.redirect(oldTerm)
end

--- Draws a square to the screen and updates the relative colour map.
--- @param screen table Represents the screen to draw on.
--- @param x number Represents the X coordinate to start drawing at.
--- @param y number Represents the Y coordinate to start drawing at.
--- @param span number The span of the square.
--- @param length number The length of the square.
--- @param colour number Represents the colour of the square.
--- @param isForeground boolean|nil Whether the square is in the foreground or background.
local function drawSquare(screen, x, y, span, length, colour, isForeground)
    local oldTerm = term.redirect(screen)
    term.setCursorPos(x,y)
    term.setBackgroundColour(colour)
    for row = 1, length, 1 do
        term.setCursorPos(x,y+row-1)
        term.write(string.rep(" ", span))
        for column = 1, span, 1 do
            local storeX = x+column-1
            local storeY = y+row-1
            if isForeground then
                foregroundColourMap[storeX] = foregroundColourMap[storeX] or {}
                foregroundColourMap[storeX][storeY] = colour
            else
                backgroundColourMap[storeX] = backgroundColourMap[storeX] or {}
                backgroundColourMap[storeX][storeY] = colour
            end
        end
    end
    term.redirect(oldTerm)
end

--- Writes to the screen and updates the relative colour map.
--- @param screen table Represents the screen to draw on.
--- @param text string The text to write.
--- @param x number Represents the X coordinate to start drawing at.
--- @param y number Represents the Y coordinate to start drawing at.
--- @param textColour number Represents the colour of the text.
--- @param backGroundColour number Represents the background colour of the text.
--- @param isForeground boolean|nil Whether the text is in the foreground or background.
local function write(screen, text, x, y, textColour, backGroundColour, isForeground)
    local oldTerm = term.redirect(screen)
    backGroundColour = backGroundColour or defaultBackgroundColour
    textColour = textColour or defaultTextColour
    term.setCursorPos(x,y)
    term.setBackgroundColour(backGroundColour)
    term.setTextColour(textColour)
    term.write(text)
    for column = 1, string.len(text), 1 do
        local storeX = x+column-1
        if isForeground then
            foregroundColourMap[storeX] = foregroundColourMap[storeX] or {}
            foregroundColourMap[storeX][y] = backGroundColour
        else
            backgroundColourMap[storeX] = backgroundColourMap[storeX] or {}
            backgroundColourMap[storeX][y] = backGroundColour
        end
    end
    term.redirect(oldTerm)
end

--- Generates a Plinko pin.
--- @param x number Represents the X coordinate of the pin.
--- @param y number Represents the Y coordinate of the pin.
local function generatePin(x, y)
    local area = {}
    for column = 1, 2, 1 do
        table.insert(area, {x = x+column, y = y})
    end
    table.insert(pinAreas, area)
end

--- Generates all Plinko pins.
--- @param midPoint number Represents the midpoint to generate pins from.
local function generateAllPins(midPoint)
    midPoint = math.floor(midPoint)
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

--- Draws all pins to the screen.
--- @param screen table Represents the screen to draw on.
local function drawAllPins(screen)
    for _, area in pairs(pinAreas) do
        for _, coord in pairs(area) do
            drawDot(screen, coord.x+1, coord.y+1, shadowColour)
            drawDot(screen, coord.x+1, coord.y+2, shadowColour)
            drawDot(screen, coord.x, coord.y, pinColour, true)
            drawDot(screen, coord.x, coord.y+1, pinColour, true)
        end
    end
end

--- Draws a Plinko goal.
--- @param screen table Represents the screen to draw on.
--- @param x number Represents the X coordinate to start drawing at.
--- @param y number Represents the Y coordinate to start drawing at.
--- @param text string The text to write.
--- @param primaryColour number Represents the primary colour of the goal.
--- @param secondaryColour number Represents the secondary colour of the goal.
--- @param textColour number Represents the colour of the text.
local function drawGoal(screen, x, y, text, primaryColour, secondaryColour, textColour)
    local oldTerm = term.redirect(screen)
    drawSquare(screen, x, y, 6, 3, primaryColour, true)
    drawSquare(screen, x+1, y+1, 4, 1, secondaryColour, true)
    term.setCursorPos(x+1, y+1)
    term.setTextColour(textColour)
    term.write(text)
    term.redirect(oldTerm)
end

--- Draws all Plinko goals.
--- @param screen table Represents the screen to draw on.
local function drawAllGoals(screen)
    local _, height = screen.getSize()
    local y = height-3
    local textColour = m_colours.darkGray
    for _, goal in pairs(goals) do
        local text = tostring(goal.value)
        drawGoal(screen, goal.startPos, y, " "..text, goal.primaryColour, goal.secondaryColour, textColour)
    end
end

--- Debugs colour maps.
--- @param screen table Represents the screen to draw on.
local function debugColourMaps(screen)
    setBackground(screen)
    local oldTerm = term.redirect(screen)
    for column, rows in pairs(backgroundColourMap) do
        for row, _ in pairs(rows) do
            term.setCursorPos(column,row)
            term.setBackgroundColour(m_colours.lime)
            term.write(" ")
        end
    end
    for column, rows in pairs(foregroundColourMap) do
        for row, _ in pairs(rows) do
            term.setCursorPos(column,row)
            term.setBackgroundColour(m_colours.purple)
            term.write(" ")
        end
    end
    term.redirect(oldTerm)
end

--- Spawns a Plinko Ball.
--- @param screen table Represents the screen.
local function spawnBall(screen)
    local width, _ = screen.getSize()
    local ball = Commons.Ball.new(math.random(width / 2 - 4, width / 2 + 5), 0, ballColour, foregroundColourMap, backgroundColourMap)
    table.insert(balls, ball)
end

--- Creates the cashout button.
--- @param screen table Represents the screen to draw on.
local function createCashoutButton(screen)
    local label = "Cash out!"
    local labelLength = string.len(label)
    local width, _ = screen.getSize()
    local x = width - labelLength - 3
    local y = 8
    local span = labelLength
    local length = 1
    local labelPad = 0
    local backgroundColourNormal = m_colours.darkGold
    local borderColourNormal = m_colours.orange
    local textColourNormal = m_colours.white
    cashoutButton = Commons.Buttons:addButton(label, EndGame, x, y, span, length, labelPad, backgroundColourNormal, borderColourNormal, textColourNormal)
end

--- Returns "right" around one in 'i' times, otherwise returns "left".
--- @param i number Odds to get "right"
--- @return string direction "right" or "left"
local function calculateStep(i)
    return (math.random(i) % i == 0) and "right" or "left"
end

--- Moves a ball horizontally.
--- @param screen table Represents the screen to draw on.
--- @param ball table The ball to move.
--- @param direction string The direcction to move in, should be "left" or "right".
--- @param velocity number How far to move.
local function moveHorizontally(screen, ball, direction, velocity)
    local directionalVelocity = ((direction == "right") and 1 or -1)
    for i = 1,velocity,1 do
        ball:move(screen, 1 * directionalVelocity, 0, defaultBackgroundColour)
        local result = ball:checkBelowBall(pinAreas)
        if not (result.left_collided or result.right_collided) and i ~= 1 then
            ball:move(screen, 0, 1, defaultBackgroundColour)
        end
        if i == velocity then return end
        sleep(0.05)
    end
end

--- Calculates what goal the ball is in.
--- @param ball table The ball to check.
--- @param midPoint table Represents the midpoint to generate pins from.
--- @return string result The name of the goal.
local function calculateGoalPos(ball, midPoint)
    local x = ball.x
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

--- Calculates the reward where the ball is.
--- @param screen table Represents the screen to draw on.
--- @param ball table The ball to calculate for.
local function calculateReward(screen, ball)
    local width, height = screen.getSize()
    local goal = calculateGoalPos(ball, width / 2)
    local multiplier = goals[goal].value
    Commons.Score:updateScore(math.ceil(Commons.Score:getScore() * multiplier))
    Commons.Score:draw(screen, 2, height/2 - 2, false, colours)
end

--- Counts the Balls on screen.
--- @return number count Then number of balls present.
local function countBalls()
    local count = 0
    for _, ball in pairs(balls) do
        if ball ~= nil then count = count + 1 end
    end
    return count
end

--- Ticks the game.
local function tick(screen, speaker)
    for i, ball in pairs(balls) do
        local result = ball:checkBelowBall(pinAreas)
        if result.left_collided or result.right_collided then
            if result.left_collided and result.right_collided then
                local direction = calculateStep(2)
                local velocity = math.random(2, 4)
                moveHorizontally(screen, ball, direction, velocity)
                playPinDing(speaker, direction)
            else
                local direction = result.left_collided and "right" or "left"
                local velocity = math.random(3)
                moveHorizontally(screen, ball, direction, velocity)
                playPinDing(speaker, direction)
            end
        else
            ball:move(screen, 0, 1, defaultBackgroundColour)
        end
        local _, height = screen.getSize()
        if ball.y >= height-3 then
            ball:move(screen, 0, -1, defaultBackgroundColour)
            calculateReward(screen, ball)
            ball:clear(screen, defaultBackgroundColour)
            balls[i] = nil
            drawAllGoals(screen)
            playEndDing(speaker)
        end
    end
end

--- Called when the monitor is touched.
--- @param x number The x coordinate touched.
--- @param y number The y coordinate touched.
local function monitorTouch(screen, x, y)
    local ballCount = countBalls()
    if Commons.Score:getScore() * (0.3 ^ (ballCount+1)) < 1.0
    then print("Out of coin!")
    elseif (ballCount >= maxBalls)
    then print("Too many balls!")
    else spawnBall(screen) end
end

--- Draws Plinko screen.
--- @param screen table Represents the screen to draw on.
local function drawScreen(screen)
    setBackground(screen)
    drawAllPins(screen)
    drawAllGoals(screen)
    Commons.Credits.selectedCredit:draw(screen, 1, 1, colours)
    local _, height = screen.getSize()
    Commons.Score:draw(screen, 2, height/2 - 2, false, colours)
    drawSquare(screen, cashoutButton.x+1, cashoutButton.y+1, cashoutButton.width, cashoutButton.height, shadowColour)
    cashoutButton:displayOnScreen(screen)
    --debugColourMaps(screen)
end

--- Starts the game.
--- @param screen table Represents the screen to draw on.
local function start(screen)
    sleep(0.1)
    if Commons.Credits.selectedCredit == nil then return end

    StartGame()
    startButton:disable()

    local width, _ = screen.getSize()
    generateAllPins(width / 2)
    createCashoutButton(screen)
    drawScreen(screen)
end

--- Creates the start button.
--- @param screen table Represents the screen to draw on.
local function createStartButton(screen)
    local label = "Start Game!"
    local width, height = screen.getSize()
    local x = math.floor(width / 2 - 1) - math.floor(#label / 2 + 1)
    local y = math.floor(height / 2 - 1) - 1
    local button = Commons.Buttons:addButton(label, function() start(screen) end, x, y, #label, 1, 1, m_colours.darkRed, m_colours.red, m_colours.white)
    return button
end

--- Draws the screen.
--- @param screen table Represents the screen to draw on.
local function drawStartScreen(screen)
    setBackground(screen)
    startButton:displayOnScreen(screen)
    if Commons.Credits.selectedCredit ~= nil then
        Commons.Credits.selectedCredit:draw(screen, 1, 1, colours)
    end
    local width, _ = screen.getSize()
    Commons.Score:draw(screen, width / 2, 3, true, colours)
end

local function redraw(screen, gameStarted)
    setPalette(screen)
    if not gameStarted then
        drawStartScreen(screen)
    else
        drawScreen(screen)
    end
end

--- Starts the game.
--- @param screen table Represents the screen to draw on.
--- @param speaker table Represents the speaker to play sounds on.
--- @param endGame function Represents the function to end the game with.
--- @param startGame function Represents the function to start the game with.
local function run(screen, speaker, endGame, startGame)
    setPalette(screen)
    startButton = createStartButton(screen)
    drawStartScreen(screen)
    EndGame = endGame
    StartGame = startGame
end

--- RETURN ---

return { run = run, colours = colours, tick = tick, monitorTouch = monitorTouch, redraw = redraw }
