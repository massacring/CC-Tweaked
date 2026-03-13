local Credit = require('Credit')

local Paint = {}
Paint.primaryBackgroundColor = 128
Paint.secondaryBackgroundColor = 256
Paint.defaultTextColor = 1

function Paint.drawSquare(window, x, y, span, length, color)
    local oldTerm = term.redirect(window)
    term.setCursorPos(x,y)
    term.setBackgroundColor(color)
    for row = 1, length, 1 do
        term.setCursorPos(x,y+row-1)
        term.write(string.rep(" ", span))
    end
    term.redirect(oldTerm)
end

function Paint.write(window, text, x, y, textColor, backGroundColor)
    local oldTerm = term.redirect(window)
    if backGroundColor == nil then
        if y % 2 == 1 then
            backGroundColor = Paint.primaryBackgroundColor
        else
            backGroundColor = Paint.secondaryBackgroundColor
        end
    end
    textColor = textColor or Paint.defaultTextColor
    term.setCursorPos(x,y)
    term.setBackgroundColor(backGroundColor)
    term.setTextColor(textColor)
    term.write(text)
    term.redirect(oldTerm)
end

function Paint.clear(window, width, height, primaryColor, secondaryColor)
    local oldTerm = term.redirect(window)
    for x=1,width,1 do
        for y=1,height,1 do
            if (y % 2 == 1) then
                term.setBackgroundColor(primaryColor)
            else
                term.setBackgroundColor(secondaryColor)
            end
            term.setCursorPos(x,y)
            term.write(" ")
        end
    end
    term.redirect(oldTerm)
end

local Credits = {}
Credits.SMALL = 1
Credits.MEDIUM = 2
Credits.LARGE = 3
Credits.credits = {
    --["emeralds"] = Credit.new("emeralds"),
    ["iron"] = Credit.new("iron", {
        [Credits.LARGE] = { ['id'] = 'minecraft:iron_block', ['multiplier'] = 9 },
        [Credits.MEDIUM] = { ['id'] = 'minecraft:iron_ingot', ['multiplier'] = 9 },
        [Credits.SMALL] = { ['id'] = 'minecraft:iron_nugget' },
    }),
}
Credits.selectedCredit = nil

function Credits.validCurrency(name)
    for _,credit in pairs(Credits.credits) do
        for _,data in pairs(credit.values) do
            if (name == data["id"]) then return true end
        end
    end
    return false
end

function Credits.getValueByName(name)
    for _,credit in pairs(Credits.credits) do
        for size,data in pairs(credit.values) do
            if (name == data["id"]) then
                local multiplier = data["multiplier"] or 1
                return multiplier ^ (size-1)
            end
        end
    end
end

function Credits.getValueBySize(size)
    if Credits.selectedCredit == nil then return nil end
    if type(size) ~= "number" then return nil end
    if size < 1 or size > 3 then return nil end
    local multiplier = Credits.credits[Credits.selectedCredit].values[size]["multiplier"]
    return multiplier ^ (size-1)
end

function Credits.getSizeByName(name)
    for _,credit in pairs(Credits.credits) do
        for size,data in pairs(credit.values) do
            if (name == data["id"]) then return size end
        end
    end
end

function Credits.getName(itemName)
    for name,credit in pairs(Credits.credits) do
        for _,data in pairs(credit.values) do
            if (itemName == data["id"]) then return name end
        end
    end
end

function Credits.getCurrentId(size)
    if Credits.selectedCredit == nil then return nil end
    if type(size) ~= "number" then return nil end
    if size < 1 or size > 3 then return nil end
    return Credits.credits[Credits.selectedCredit].values[size]["id"]
end

function Credits.drawCredit(window, x, y, textColor, backGroundColor)
    local label = "Credit Type: " .. Credits.selectedCredit

    Paint.write(window, label, x, y, textColor, backGroundColor)
end

local Score = {}
Score.value = 0
Score.max = 10000
Score.min = 4

function Score.updateScore(num)
    print("Updating score: " .. tostring(num))
    Score.value = num
end

function Score.getScore()
    print("Score is: " .. tostring(Score.value))
    return Score.value
end

function Score.drawScore(window, x, y, primaryTextColor, primaryBackgroundColor, secondaryTextColor, secondaryBackgroundColor, offset)
    local scoreTitle = "Score:"
    local scoreText = tostring(Score.value)
    local scoreTextLen = string.len(scoreText) + 2
    if scoreTextLen < 13 then scoreTextLen = 13 end
    if offset then x = x - math.floor(scoreTextLen / 2) end

    Paint.write(window, scoreTitle, x+1, y, secondaryTextColor, secondaryBackgroundColor)
    Paint.drawSquare(window, x, y+1, scoreTextLen, 3, primaryBackgroundColor)
    Paint.write(window, scoreText, x+1, y+2, primaryTextColor, primaryBackgroundColor)
end

return { Paint = Paint, Credits = Credits, Score = Score }