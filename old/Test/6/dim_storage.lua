local dim = peripheral.wrap("front");
--local s, data = turtle.inspect()
print(textutils.serialise(peripheral.getMethods("front")))