local Images = require("Images")

local Card = {}
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

return Card