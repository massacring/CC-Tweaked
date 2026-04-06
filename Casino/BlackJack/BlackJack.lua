--- VARIABLES ---

local Images = {}
local Hand = {}
local Card = {}
local Button = {}

--- IMAGES ---

Images.__index = Images
Images.num1 = paintutils.parseImage([[
 32
  2
  2
  1
 211
]])
Images.num2 = paintutils.parseImage([[
 32
3  1
  2
 2
2111
]])
Images.num3 = paintutils.parseImage([[
 32
3  2
  1
2  1
 21
]])
Images.num4 = paintutils.parseImage([[
3  2
3  1
2211
   1
   1
]])
Images.num5 = paintutils.parseImage([[
3322
2
 211
   1
211
]])
Images.num6 = paintutils.parseImage([[
 322
3
221
2  1
 11
]])
Images.num7 = paintutils.parseImage([[
3322
   1
  1
 1
2
]])
Images.num8 = paintutils.parseImage([[
 32
3  1
 21
2  1
 11
]])
Images.num9 = paintutils.parseImage([[
 32
3  1
 211
   1
211
]])
Images.num0 = paintutils.parseImage([[
 32
3  1
2  1
2  1
 11
]])
Images.jack = paintutils.parseImage([[
332
   2
   1
2  1
 21
]])
Images.queen = paintutils.parseImage([[
 32
3  2
2  1
2 1
 1 1
]])
Images.king = paintutils.parseImage([[
3  1
3 2
22
2 1
2  1
]])
Images.ace = paintutils.parseImage([[
 32
3  1
2211
2  1
2  1
]])
Images.joker = paintutils.parseImage([[
  649
  5aa9
    a9 9
  a9aaaa95
 5aaaaaa456
654aaaa9 4
 4  9999
    2211
]])
Images.spade = paintutils.parseImage([[
  2
 231
23211
  1
 211
]])
Images.heart = paintutils.parseImage([[
 5 4
56544
55544
 544
  4
]])
Images.club = paintutils.parseImage([[
 222
23211
22111
  1
 211
]])
Images.diamond = paintutils.parseImage([[
  5
 564
56544
 544
  4
]])
Images.bust = paintutils.parseImage([[
 32222  3     2   3222   32221
3     2 3     2  3    1 3  2  1
2     2 2     2 2          2
2    2  2     2  2         2
22222   2     1   222      2
2    1  2     1      1     2
2     1  2   1        1    1
2     1  2   1  2    1     1
 21111    211    2211     211
]])
Images.win = paintutils.parseImage([[
 3   2   3221 3    2
3     2 3 2   32    2
2     2   2   2 2   2
2     1   2   2 2   1
 2   1    2   2  2  1
 2 2 1    1   2   2 1
 2 2 1    1   2   1 1
  2 1     1 1 2    11
  2 1   2111   2    1
]])
Images.draw = paintutils.parseImage([[
 3222   32222     322    3   2
3    2  3    2   3   2  3     2
2     2 2     2 2     1 2     2
2     1 2     1 2     1 2     1
2     1 2    1  2222211  2   1
2     1 22221   2     1  2 2 1
2     1 2    1  2     1  2 2 1
2    1  2     1 2     1   2 1
 2211   2     1 2     1   2 1
]])

local cardLength = 13
local cardHeight = 13

function Images:drawJoker(window, x, y)
    local oldTerm = term.redirect(window)
    local borderColor = 2
    local background = 1

    term.setCursorPos(x+1, y)
    term.setBackgroundColor(borderColor)
    term.write(string.rep(" ", cardLength))

    for i=1, cardHeight, 1 do
        term.setCursorPos(x, y+i)
        term.setBackgroundColor(borderColor)
        term.write(" ")

        term.setCursorPos(x+1, y+i)
        term.setBackgroundColor(background)
        term.write(string.rep(" ", cardLength))

        term.setCursorPos(x+1+cardLength, y+i)
        term.setBackgroundColor(borderColor)
        term.write(" ")
    end

    term.setCursorPos(x+1, y+1+cardHeight)
    term.setBackgroundColor(borderColor)
    term.write(string.rep(" ", cardLength))

    term.setBackgroundColor(borderColor)
    for i=1,cardHeight,(cardHeight-1) do
        term.setCursorPos(x+1, y+i)
        term.write(" ")
        term.setCursorPos(x+cardLength, y+i)
        term.write(" ")
    end

    paintutils.drawImage(Images.joker, x+2, y+3)
    term.redirect(oldTerm)
end

function Images:drawCard(window, x, y, num, suit)
    local oldTerm = term.redirect(window)
    local borderColor = 2
    local numBackground = 1
    local suitBackgroundPrimary
    local suitBackgroundSecondary
    local suitImg

    if suit == "spade" or suit == "club" then
        suitBackgroundPrimary = 32
        suitBackgroundSecondary = 16
    elseif suit == "heart" or suit == "diamond" then
        suitBackgroundPrimary = 8
        suitBackgroundSecondary = 4
    end

    if suit == "spade" then
        suitImg = Images.spade
    elseif suit == "heart" then
        suitImg = Images.heart
    elseif suit == "club" then
        suitImg = Images.club
    elseif suit == "diamond" then
        suitImg = Images.diamond
    end

    term.setCursorPos(x+1, y)
    term.setBackgroundColor(borderColor)
    term.write(string.rep(" ", cardLength))

    for i=1, cardHeight, 1 do
        term.setCursorPos(x, y+i)
        term.setBackgroundColor(borderColor)
        term.write(" ")

        for j=1, cardLength, 1 do
            term.setCursorPos(x+j, y+i)
            local diagonal_forward = j + i <= math.floor((cardLength + cardHeight) / 2)+1
            local diagonal_backward = j - i >= 1
            if (i == j) then
                term.setBackgroundColor(borderColor)
            elseif (diagonal_backward) then
                if (diagonal_forward) then
                    term.setBackgroundColor(suitBackgroundPrimary)
                else
                    term.setBackgroundColor(suitBackgroundSecondary)
                end
            else
                term.setBackgroundColor(numBackground)
            end
            term.write(" ")
        end

        term.setCursorPos(x+1+cardLength, y+i)
        term.setBackgroundColor(borderColor)
        term.write(" ")
    end

    term.setCursorPos(x+1, y+1+cardHeight)
    term.setBackgroundColor(borderColor)
    term.write(string.rep(" ", cardLength))

    term.setBackgroundColor(borderColor)
    for i=1,cardHeight,(cardHeight-1) do
        term.setCursorPos(x+1, y+i)
        term.write(" ")
        term.setCursorPos(x+cardLength, y+i)
        term.write(" ")
    end

    paintutils.drawImage(suitImg, x+cardLength-5, y+2)
    paintutils.drawImage(num, x+2, y+cardHeight-5)
    term.redirect(oldTerm)
end

function Images:drawFaceDown(window, x, y)
    local oldTerm = term.redirect(window)
    local borderColor = 1
    local primaryColor = 32
    local secondaryColor = 16

    term.setCursorPos(x+1, y)
    term.setBackgroundColor(borderColor)
    term.write(string.rep(" ", cardLength))

    for i=1, cardHeight, 1 do
        term.setCursorPos(x, y+i)
        term.setBackgroundColor(borderColor)
        term.write(" ")

        for j=1, cardLength, 1 do
            if (i + j) % 2 == 1 then
                term.setBackgroundColor(primaryColor)
            else
                term.setBackgroundColor(secondaryColor)
            end
            term.setCursorPos(x+j, y+i)
            term.write(" ")
        end

        term.setCursorPos(x+1+cardLength, y+i)
        term.setBackgroundColor(borderColor)
        term.write(" ")
    end

    term.setCursorPos(x+1, y+1+cardHeight)
    term.setBackgroundColor(borderColor)
    term.write(string.rep(" ", cardLength))

    term.setBackgroundColor(borderColor)
    for i=1,cardHeight,(cardHeight-1) do
        term.setCursorPos(x+1, y+i)
        term.write(" ")
        term.setCursorPos(x+cardLength, y+i)
        term.write(" ")
    end

    term.redirect(oldTerm)
end

function Images:drawBust(window, x, y)
    local oldTerm = term.redirect(window)
    local length = 34
    local height = 13
    x = x - math.floor(length/2)
    y = y - math.floor(height/2)
    for i=1,height,1 do
        if i == 1 or i == height then
            term.setBackgroundColor(2)
        elseif (i > 6) then
            term.setBackgroundColor(512)
        else
            term.setBackgroundColor(1024)
        end
        term.setCursorPos(x, y+i-1)
        term.write(string.rep(" ", length))

        term.setBackgroundColor(2)
        term.setCursorPos(x, y+i-1)
        term.write(" ")
        term.setCursorPos(x + length, y+i-1)
        term.write(" ")
    end

    paintutils.drawImage(Images.bust, x+2, y+2)

    term.redirect(oldTerm)
end

function Images:drawWin(window, x, y)
    local oldTerm = term.redirect(window)
    local length = 24
    local height = 13
    x = x - math.floor(length/2)
    y = y - math.floor(height/2)
    for i=1,height,1 do
        if i == 1 or i == height then
            term.setBackgroundColor(2)
        elseif (i > 6) then
            term.setBackgroundColor(512)
        else
            term.setBackgroundColor(1024)
        end
        term.setCursorPos(x, y+i-1)
        term.write(string.rep(" ", length))

        term.setBackgroundColor(2)
        term.setCursorPos(x, y+i-1)
        term.write(" ")
        term.setCursorPos(x + length, y+i-1)
        term.write(" ")
    end

    paintutils.drawImage(Images.win, x+2, y+2)

    term.redirect(oldTerm)
end

function Images:drawDraw(window, x, y)
    local oldTerm = term.redirect(window)
    local length = 34
    local height = 13
    x = x - math.floor(length/2)
    y = y - math.floor(height/2)
    for i=1,height,1 do
        if i == 1 or i == height then
            term.setBackgroundColor(2)
        elseif (i > 6) then
            term.setBackgroundColor(512)
        else
            term.setBackgroundColor(1024)
        end
        term.setCursorPos(x, y+i-1)
        term.write(string.rep(" ", length))

        term.setBackgroundColor(2)
        term.setCursorPos(x, y+i-1)
        term.write(" ")
        term.setCursorPos(x + length, y+i-1)
        term.write(" ")
    end

    paintutils.drawImage(Images.draw, x+2, y+2)

    term.redirect(oldTerm)
end

--- HAND ---

Hand.__index = Hand

function Hand.new(includeJoker)
    local hand = setmetatable({}, Hand)
    hand.cards = {}
    hand.cardAmount = 0
    hand:addCard(Card.newRandom(includeJoker))
    hand:addCard(Card.newRandom(includeJoker))
    return hand
end

function Hand:addCard(card)
    table.insert(self.cards, card)
    self.cardAmount = self.cardAmount + 1
end

function Hand:getCards()
    return self.cards
end

function Hand:getValue()
    local total = 0
    local aces = {}
    for _, card in pairs(self.cards) do
        if card.isAce then
            table.insert(aces, card)
        else
            total = total + card.value
        end
    end
    for i=1,#aces,1 do
        if total + #aces - i <= 10 then
            total = total + 11
        else
            total = total + 1
        end
    end
    return total
end

function Hand:evaluateHand()
    local totalValue = self:getValue()
    if totalValue == 21 and self.cardAmount == 2 then
        -- BlackJack
        return 22
    end
    if totalValue > 21 then
        -- Bust
        return 0
    end
    return totalValue
end

function Hand:draw(window, width, y, first)
    local amount = self.cardAmount
    local startX = width / 2 - 7 - (9 * (amount-1))
    if amount > 3 then
        startX = startX + math.floor((9 * (amount-2)) / 2) + 2
    end
    local cards = self.cards
    for i, card in ipairs(cards) do
        local boost = (16 * (i-1))
        if i < amount-1 then
            boost = (7 * (i-1))
        elseif amount > 3 then
            boost = (7 * (amount - 3)) + (16 * (2 - (amount - i)))
        end
        local x = startX + boost
        if i == amount and first then
            card:drawFaceDown(window, x, y)
        else
            card:draw(window, x, y)
        end
    end
end

--- CARD ---

Card.__index = Card
Card.suits = {
    "spade",
    "heart",
    "club",
    "diamond"
}
Card.numbers = {
    Images.num1,
    Images.num2,
    Images.num3,
    Images.num4,
    Images.num5,
    Images.num6,
    Images.num7,
    Images.num8,
    Images.num9
}
Card.courts = {
    Images.jack,
    Images.queen,
    Images.king,
    Images.ace,
}

function Card.new(value, suit)
    local card = setmetatable({}, Card)
    if value == 14 then
        card.isJoker = true
        return card
    elseif value < 10 and value > 0 then
        card.num = Card.numbers[value]
        card.isCourt = true
        card.value = value
    elseif value < 13 and value > 9 then
        card.num = Card.courts[value-9]
        card.isNumber = true
        card.value = 10
    else
        card.num = Images.ace
        card.isAce = true
        card.value = 11
    end
    card.suit = suit
    return card
end

function Card.newRandom(includeJoker)
    local card = setmetatable({}, Card)
    local joker = false
    if includeJoker then
        joker = math.random(1,27) == 1
    end
    if joker then
        card.isJoker = true
        return card
    end
    card.suit = Card.suits[math.random(1,4)]
    local value = math.random(2,13)
    if value < 10 then
        card.num = Card.numbers[value]
        card.isNumber = true
        card.value = value
    elseif value < 13 then
        card.num = Card.courts[value-9]
        card.isCourt = true
        card.value = 10
    else
        card.num = Images.ace
        card.isAce = true
        card.value = 11
    end
    return card
end

function Card.drawWin(window, x, y)
    Images:drawWin(window, x, y)
end

function Card.drawBust(window, x, y)
    Images:drawBust(window, x, y)
end

function Card.drawDraw(window, x, y)
    Images:drawDraw(window, x, y)
end

function Card:draw(window, x, y)
    if self.isJoker then
        Images:drawJoker(window, x,y)
        return
    end
    Images:drawCard(window, x,y, self.num, self.suit)
end

function Card:drawFaceDown(window, x, y)
    Images:drawFaceDown(window, x, y)
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

--- RETURN --- 

return { Images = Images, Hand = Hand, Card = Card, Button = Button }
