local direction = arg[1]
local amount = tonumber(arg[2]) or 1

if direction == "right" or direction == "r" then
    for _ = 1, amount, 1 do turtle.turnRight() end
else
    for _ = 1, amount, 1 do turtle.turnLeft() end
end
