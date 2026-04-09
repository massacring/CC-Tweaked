--- VARIABLES ---
local Commons = require("CasinoCommons")

local multiplier = 2

-- Declares my own colors
local m_colors = {
    white = colors.white,
    black = colors.orange,
    gray = colors.magenta,
    lightGray = colors.lightBlue,
    darkRed = colors.yellow,
    red = colors.lime,
    lightRed = colors.pink,
    green = colors.gray,
    lightGreen = colors.lightGray,
    darkYellow = colors.cyan,
    yellow = colors.purple,
}

local colours = {
    creditTextColour = m_colors.white,
    creditBackgroundColour = m_colors.red,
    scoreTitleTextColour = m_colors.white,
    scoreTitleBackgroundColour = m_colors.lightGray,
    scoreValueTextColour = m_colors.white,
    scoreValueBackgroundColour = m_colors.yellow
}

local primaryBackgroundColor = m_colors.green
local secondaryBackgroundColor = m_colors.lightGreen

--- BLACKJACK ---
local playerHand = Commons.Hand.new(false, 2, false)
local dealerHand = Commons.Hand.new(false, 2, true)
while dealerHand:evaluateHand() >= 21 do
    dealerHand = Commons.Hand.new(false, 2, true)
    sleep(0.05)
end
dealerHand.cards[1].faceDown = false

local gameButtons = {}
local startButton = {}

local EndGame

--- Plays the draw card sound.
--- @param speaker table Represents the speaker to play the sound with.
local function playCardDraw(speaker)
    speaker.playSound("entity.villager.work_librarian")
end

--- Changes the default palette
--- @param screen table Represents the screen to draw on.
local function setPalette(screen)
    screen.setPaletteColor(colors.orange, 0x191919) -- Black
    screen.setPaletteColor(colors.magenta, 0x262626) -- Gray
    screen.setPaletteColor(colors.lightBlue, 0x565656) -- Light Gray
    screen.setPaletteColor(colors.yellow, 0xDD2F00) -- Dark Red
    screen.setPaletteColor(colors.lime, 0xEF4A21) -- Red
    screen.setPaletteColor(colors.pink, 0xFFBAAA) -- Light Red
    screen.setPaletteColor(colors.gray, 0x355E19) -- Green
    screen.setPaletteColor(colors.lightGray, 0x356D19) -- Light Green
    screen.setPaletteColor(colors.cyan, 0xEAB327) -- Dark Yellow
    screen.setPaletteColor(colors.purple, 0xEDC125) -- Yellow
    screen.setPaletteColor(colors.blue, 0xE8C958) -- Light Yellow
    --screen.setPaletteColor(colors.brown, 0xE8C958) -- 
    --screen.setPaletteColor(colors.green, 0xE8C958) -- 
    --screen.setPaletteColor(colors.red, 0xE8C958) -- 
    --screen.setPaletteColor(colors.black, 0xE8C958) -- 
end

--- Sets the background of the game.
--- @param screen table Represents the screen to draw on.
local function setBackground(screen)
    local oldTerm = term.redirect(screen)
    local width, height = screen.getSize()
    for x=1,width,1 do
        for y=1,height,1 do
            if (y % 2 == 1) then
                term.setBackgroundColor(primaryBackgroundColor)
            else
                term.setBackgroundColor(secondaryBackgroundColor)
            end
            term.setCursorPos(x,y)
            term.write(" ")
        end
    end
    term.redirect(oldTerm)
end

--- Clears one side of the game.
--- @param screen table Represents the screen to draw on.
local function clearSide(screen, side)
    local oldTerm = term.redirect(screen)
    local start,limit
    local width, height = screen.getSize()
    if side == "up" then
        start = 2
        limit = height/2-3
    elseif side == "down" then
        start = height/2+3
        limit = height
    else
        error("Invalid side.", 2)
    end
    for x=1,width,1 do
        for y=start,limit,1 do
            if (y % 2 == 1) then
                term.setBackgroundColor(m_colors.green)
            else
                term.setBackgroundColor(m_colors.lightGreen)
            end
            term.setCursorPos(x,y)
            term.write(" ")
        end
    end
    term.redirect(oldTerm)
end

--- Sets up the dealer.
--- @param screen table Represents the screen to draw on.
local function setupDealer(screen)
    clearSide(screen, "up")
    local width, _ = screen.getSize()
    dealerHand:draw(screen, width, 2)
end

--- Sets up the player.
--- @param screen table Represents the screen to draw on.
local function setupPlayer(screen)
    clearSide(screen, "down")

    local width, height = screen.getSize()
    playerHand:draw(screen, width, height-16)
end

--- Player loses.
--- @param resetScore boolean Whether to set score to 0 before ending game.
local function loseGame(resetScore)
    if resetScore == true then
        Commons.Score:updateScore(0)
    end
    sleep(3)
    EndGame()
end

--- Player wins.
--- @param screen table Represents the screen to draw on.
local function winGame(screen)
    Commons.Score:updateScore(Commons.Score:getScore() * multiplier)
    local width, height = screen.getSize()
    Commons.Images:drawWin(screen, math.floor(width/2), math.floor(height/2))
    sleep(3)
    EndGame()
end

--- Compares the hands of the player and dealer, and ends the game.
--- @param screen table Represents the screen to draw on.
local function compareHands(screen)
    local playerValue = playerHand:evaluateHand()
    local dealerValue = dealerHand:evaluateHand()
    local width, height = screen.getSize()
    if playerValue > dealerValue then
        winGame(screen)
    elseif playerValue < dealerValue then
        Commons.Images:drawLose(screen, math.floor(width/2), math.floor(height/2))
        loseGame(true)
    else
        Commons.Images:drawDraw(screen, math.floor(width/2), math.floor(height/2))
        loseGame(true)
    end
end

--- Plays the dealers turn.
--- @param screen table Represents the screen to draw on.
--- @param speaker table Represents the speaker to play sounds on.
local function dealerPlay(screen, speaker)
    for _, card in ipairs(dealerHand.cards) do
        card.faceDown = false
        playCardDraw(speaker)
        setupDealer(screen)
        sleep(0.5)
    end
    while true do
        playCardDraw(speaker)
        dealerHand:addCard(Commons.Card.newRandom(false, false))
        local eval = dealerHand:evaluateHand()
        sleep(0.5)
        if eval == 0 then
            winGame(screen)
        elseif eval >= 17 then
            compareHands(screen)
        end
        sleep(0.5)
    end
end

--- Player stands their turn.
--- @param screen table Represents the screen to draw on.
--- @param speaker table Represents the speaker to play sounds on.
local function stand(screen, speaker)
    dealerPlay(screen, speaker)
end

--- Player hits.
--- @param screen table Represents the screen to draw on.
--- @param speaker table Represents the speaker to play sounds on.
local function hit(screen, speaker)
    playCardDraw(speaker)
    playerHand:addCard(Commons.Card.newRandom(false, false))
    playCardDraw(speaker)
    setupPlayer(screen)
    local eval = playerHand:evaluateHand()
    sleep(0.5)
    if eval == 0 then
        Commons.Score:updateScore(0)
        local width, height = screen.getSize()
        Commons.Images:drawBust(screen, math.floor(width/2), math.floor(height/2))
        sleep(3)
        EndGame()
    end
end

--- Player doubles down.
--- @param screen table Represents the screen to draw on.
--- @param speaker table Represents the speaker to play sounds on.
local function double(screen, speaker)
    multiplier = multiplier * 2
    hit(screen, speaker)
    stand(screen, speaker)
end

--- Player forfeits.
--- @param screen table Represents the screen to draw on.
local function surrender(screen)
    Commons.Score:updateScore(math.floor(Commons.Score:getScore()/2))
    local width, height = screen.getSize()
    Commons.Images:drawSurrender(screen, math.floor(width/2), math.floor(height/2))
    loseGame(false)
end

--- Creates the player action buttons.
--- @param screen table Represents the screen to draw on.
--- @param speaker table Represents the speaker to play sounds on.
--- @return table buttons The buttons created.
local function createButtons(screen, speaker)
    local buttons = {}
    local labelMap = {
        ["Hit"] = function() hit(screen, speaker) end,
        ["Stand"] = function() stand(screen, speaker) end,
        --["Double Down"] = double,
        ["Surrender"] = function() surrender(screen) end
    }
    local labels = {
        "Hit",
        "Stand",
        --"Double Down",
        "Surrender"
    }
    local totalLength = 0
    for _, label in ipairs(labels) do
        totalLength = totalLength + #label + 3
    end
    local width, height = screen.getSize()
    local startX = math.floor(width / 2) - math.floor(totalLength / 2)
    local x = startX
    local y = math.floor(height / 2 - 1)
    for _, label in ipairs(labels) do
        local button = Commons.Buttons:addButton(label, labelMap[label], x, y, #label, 1, 0, m_colors.red, m_colors.darkRed, m_colors.white)
        table.insert(buttons, button)
        x = x + #label + 3
    end
    return buttons
end

--- Draws a batch of buttons to the screen.
--- @param screen table Represents the screen to draw on.
--- @param buttons table Represents the buttons to draw.
local function drawButtons(screen, buttons)
    for _, button in ipairs(buttons) do
        button:displayOnScreen(screen)
    end
end

--- Starts the game.
--- @param screen table Represents the screen to draw on.
--- @param speaker table Represents the speaker to play sounds on.
local function start(screen, speaker)
    sleep(0.1)
    if Commons.Credits.selectedCredit == nil then return end
    startButton:disable()
    setBackground(screen)
    Commons.Credits.selectedCredit:draw(screen, 1, 1, colours)
    local _, height = screen.getSize()
    Commons.Score:draw(screen, 2, height/2 - 2, true, colours)

    playCardDraw(speaker)
    setupDealer(screen)
    setupPlayer(screen)
    gameButtons = createButtons(screen, speaker)
    drawButtons(screen, gameButtons)
end

--- Creates the start button.
--- @param screen table Represents the screen to draw on.
--- @param speaker table Represents the speaker to play sounds on.
local function createStartButton(screen, speaker)
    local label = "Start Game!"
    local width, height = screen.getSize()
    local x = math.floor(width / 2 - 1) - math.floor(#label / 2 + 1)
    local y = math.floor(height / 2 - 1) - 1
    local button = Commons.Buttons:addButton(label, function() start(screen, speaker) end, x, y, #label, 1, 1, m_colors.darkRed, m_colors.red, m_colors.white)
    return button
end

--- Draws the screen.
--- @param screen table Represents the screen to draw on.
local function drawStartScreen(screen)
    setBackground(screen)
    startButton:displayOnScreen(screen)
    local width, _ = screen.getSize()
    Commons.Score:draw(screen, width / 2, 3, true, colours)
end

--- Starts the game.
--- @param screen table Represents the screen to draw on.
--- @param speaker table Represents the speaker to play sounds on.
--- @param endGame function Represents the function to end the game with.
local function startGame(screen, speaker, endGame)
    setPalette(screen)
    startButton = createStartButton(screen, speaker)
    drawStartScreen(screen)
    EndGame = endGame
end

return { startGame = startGame, colours = colours }
