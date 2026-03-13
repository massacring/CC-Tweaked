local Credit = {}
Credit.__index = Credit

function Credit.new(name, values)
    local credit = setmetatable({}, Credit)

    credit.name = name
    credit.values = values or {
        [3] = { ['id'] = 'minecraft:emerald_block', ['multiplier'] = 9 },
        [2] = { ['id'] = 'minecraft:emerald', ['multiplier'] = 9 },
        [1] = { ['id'] = 'embercrest:emerald_nugget' },
    }

    return credit
end

return Credit