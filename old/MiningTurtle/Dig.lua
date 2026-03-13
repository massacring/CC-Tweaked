local direction = arg[1]
if direction == "up" or direction == "u" then
    turtle.digUp()
elseif direction == "down" or direction == "d" then
    turtle.digDown()
else
    turtle.dig()
end
