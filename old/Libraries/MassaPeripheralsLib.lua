local function tlength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

local function getOnePeripheral(type, filter)
    local peripherals = { peripheral.find(type, filter) }
    if not (tlength(peripherals) == 1) then error("You need exactly one "..type.." attached.", 0) end
    for _, peripheral in pairs(peripherals) do
        return peripheral
    end
end

local function getPeripheralTypes()
    local peripherals = {}
    for key, value in pairs(peripheral.getNames()) do
        local _peripheral = peripheral.getType(value)
        table.insert(peripherals, _peripheral)
    end
    return peripherals
end

return { getOnePeripheral = getOnePeripheral, getPeripheralTypes = getPeripheralTypes }