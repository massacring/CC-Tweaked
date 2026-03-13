local direction = arg[1]
if direction == "up" or direction == "u" then
    turtle.placeUp()
elseif direction == "down" or direction == "d" then
    turtle.placeDown()
else
    turtle.place()
end

