function DetectLiquid(data, liquid, flowing)
    if not liquid then liquid = "minecraft:water" end

    if not data.name then return false end
    if not data.name == liquid then return false end
    if not data.state then return false end
    if not data.state.level then return false end

    local level = data.state.level

    if flowing then return level > 0
    else return level == 0 end
end

function PlaceIngredients()
    local has_block, data = turtle.inspectDown()
    if not has_block then return end
    if not DetectLiquid(data, "pneumaticcraft:yeast_culture", true) then return end

    turtle.drop(1)
    sleep(0.25)
    redstone.setOutput("left", true)
    sleep(0.1)
    redstone.setOutput("left", false)
end

function GrabYeast()
    local has_block, data = turtle.inspect()
    if not data.name then return end
    if not data.state then return end
    if not data.state.level then return end
    
    print(data.name, " | ", data.state.level)
    if not has_block then return end
    if not DetectLiquid(data, "pneumaticcraft:yeast_culture", false) then return false end

    redstone.setOutput("right", true)
    sleep(0.1)
    redstone.setOutput("right", false)
    return true
end

while true do
    sleep(1)
    PlaceIngredients()
end

for i=1,100,1 do turtle.forward() end