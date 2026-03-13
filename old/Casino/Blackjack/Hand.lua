local Card = require("Card")
local Hand = {}
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

return Hand