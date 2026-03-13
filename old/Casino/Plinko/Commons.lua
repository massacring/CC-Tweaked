local Credit = require('Credit')
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
Credits.__index = Credits

function Credits:validCurrency(name)
    for _,credit in pairs(Credits.credits) do
        for _,data in pairs(credit.values) do
            if (name == data["id"]) then return true end
        end
    end
    return false
end

function Credits:getValueByName(name)
    for _,credit in pairs(Credits.credits) do
        for size,data in pairs(credit.values) do
            if (name == data["id"]) then
                local multiplier = data["multiplier"] or 1
                return multiplier ^ (size-1)
            end
        end
    end
end

function Credits:getValueBySize(size)
    if Credits.selectedCredit == nil then return nil end
    if type(size) ~= "number" then return nil end
    if size < 1 or size > 3 then return nil end
    local multiplier = Credits.credits[Credits.selectedCredit].values[size]["multiplier"]
    return multiplier ^ (size-1)
end

function Credits:getSizeByName(name)
    for _,credit in pairs(Credits.credits) do
        for size,data in pairs(credit.values) do
            if (name == data["id"]) then return size end
        end
    end
end

function Credits:getName(itemName)
    for name,credit in pairs(Credits.credits) do
        for _,data in pairs(credit.values) do
            if (itemName == data["id"]) then return name end
        end
    end
end

function Credits:getCurrentId(size)
    if Credits.selectedCredit == nil then return nil end
    if type(size) ~= "number" then return nil end
    if size < 1 or size > 3 then return nil end
    return Credits.credits[Credits.selectedCredit].values[size]["id"]
end

local Score = {}
Score.__index = Score
Score.value = 0
Score.max = 10000
Score.min = 4

function Score:updateScore(num)
    print("Updating score: " .. tostring(num))
    Score.value = num
end

function Score:getScore()
    print("Score is: " .. tostring(Score.value))
    return Score.value
end

return { Credits = Credits, Score = Score }