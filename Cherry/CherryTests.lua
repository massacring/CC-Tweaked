local Cherry = require("Cherry")
local CHERRY = Cherry.openUIElement
local Builder = Cherry.buildUIElement
local FIXED = Cherry.FIXED
local GROW = Cherry.GROW
local FIT = Cherry.FIT

--[[ 
  Draws an ASCII representation of the layout for debugging.
  Each element is represented by its backgroundColor number.
--]]
local function visualize(element, indent)
    indent = indent or ""
    local width = element.width
    local height = element.height
    print(string.format("%sElement direction=%s size=(%d,%d)", indent, element.direction or "?", width, height))
    for _, child in ipairs(element.children) do
        visualize(child, indent .. "  ")
    end
end

local function makeAssertion(element, num, direction, required)
    local size, type
    if direction == "across" or direction == "along" then
        size = element:getSize(direction)
        type = element:getSizing(direction)
    elseif direction == "height" or direction == "width" then
        size = element[direction]
        if direction == "height" then
            type = element.heightSizing
        else
            type = element.widthSizing
        end
    end
    local message = string.format("Child %s: %s %s [%d] but is (%d)", tostring(num), (type:lower():gsub("^%l", string.upper)), (direction:lower():gsub("^%l", string.upper)), required, size)
    assert(size == required, message)
end

local function test_horizontalGrow(verbose)
    local spec = CHERRY{
        name = "root",
        direction = "LEFT_TO_RIGHT",
        size = { FIT(), FIT() },
        padding = { left=1, top=1, right=1, bottom=1 },
    }{
        CHERRY{ name = "child1", size = { FIXED(5), FIXED(3) }, backgroundColor = 1 }(),
        CHERRY{ name = "child2", size = { GROW(), FIXED(3) }, backgroundColor = 2 }(),
        CHERRY{ name = "child3", size = { FIXED(3), FIXED(3) }, backgroundColor = 3 }(),
    }

    local container = Builder(spec)

    Cherry:layout()
    if verbose then visualize(container) end

    makeAssertion(container, 0, "width", 20)
    makeAssertion(container, 0, "along", 20)
    makeAssertion(container, 0, "height", 5)
    makeAssertion(container, 0, "across", 5)

    makeAssertion(container.children[1], 1, "width", 5)
    makeAssertion(container.children[1], 1, "along", 5)
    makeAssertion(container.children[1], 1, "height", 3)
    makeAssertion(container.children[1], 1, "across", 3)

    makeAssertion(container.children[2], 2, "width", 10)
    makeAssertion(container.children[2], 2, "along", 10)
    makeAssertion(container.children[2], 2, "height", 3)
    makeAssertion(container.children[2], 2, "across", 3)

    makeAssertion(container.children[3], 3, "width", 3)
    makeAssertion(container.children[3], 3, "along", 3)
    makeAssertion(container.children[3], 3, "height", 3)
    makeAssertion(container.children[3], 3, "across", 3)
end

local function test_verticalGrow(verbose)
    local spec = CHERRY{
        name = "root",
        direction = "TOP_TO_BOTTOM",
        size = { FIT(), FIT() },
        padding = { left=1, top=1, right=1, bottom=1 },
    }{
        CHERRY{ name = "child1", size = { FIXED(3), FIXED(5) }, backgroundColor = 1 }(),
        CHERRY{ name = "child2", size = { FIXED(3), GROW() }, backgroundColor = 2 }(),
        CHERRY{ name = "child3", size = { FIXED(3), FIXED(3) }, backgroundColor = 3 }(),
    }

    local container = Builder(spec)

    Cherry:layout()
    if verbose then visualize(container) end

    makeAssertion(container, 0, "height", 20)
    makeAssertion(container, 0, "along", 20)
    makeAssertion(container, 0, "width", 5)
    makeAssertion(container, 0, "across", 5)

    makeAssertion(container.children[1], 1, "height", 5)
    makeAssertion(container.children[1], 1, "along", 5)
    makeAssertion(container.children[1], 1, "width", 3)
    makeAssertion(container.children[1], 1, "across", 3)

    makeAssertion(container.children[2], 2, "height", 10)
    makeAssertion(container.children[2], 2, "along", 10)
    makeAssertion(container.children[2], 2, "width", 3)
    makeAssertion(container.children[2], 2, "across", 3)

    makeAssertion(container.children[3], 3, "height", 3)
    makeAssertion(container.children[3], 3, "along", 3)
    makeAssertion(container.children[3], 3, "width", 3)
    makeAssertion(container.children[3], 3, "across", 3)
end

local function test_nestedGrow(verbose)
    local spec = CHERRY{
        name = "root",
        direction = "TOP_TO_BOTTOM",
        size = { FIT(), FIT() },
        padding = { top=1, left=1, right=1, bottom=1 },
        childGap = 1,
    }{
        CHERRY{
            name = "child1",
            direction = "LEFT_TO_RIGHT",
            size = { GROW(), FIXED(3) },
            backgroundColor = 8,
        }{
            CHERRY{ name = "child1.1", size = { FIXED(4), FIXED(3) }, backgroundColor = 4 }(),
            CHERRY{ name = "child1.2", size = { GROW(), FIXED(3) }, backgroundColor = 5 }(),
        },
        CHERRY{ name = "child2", size = { FIXED(3), GROW() }, backgroundColor = 2 }(),
    }

    local container = Builder(spec)

    Cherry:layout()
    if verbose then visualize(container) end

    makeAssertion(container, 0, "height", 10)
    makeAssertion(container, 0, "along", 10)
    makeAssertion(container, 0, "width", 15)
    makeAssertion(container, 0, "across", 15)

    makeAssertion(container.children[1], 1, "width", 13)
    makeAssertion(container.children[1], 1, "along", 13)
    makeAssertion(container.children[1], 1, "height", 3)
    makeAssertion(container.children[1], 1, "across", 3)

    local topRow = container.children[1]
    makeAssertion(topRow.children[1], 1.1, "width", 4)
    makeAssertion(topRow.children[1], 1.1, "along", 4)
    makeAssertion(topRow.children[1], 1.1, "height", 3)
    makeAssertion(topRow.children[1], 1.1, "across", 3)

    makeAssertion(topRow.children[2], 1.2, "width", 9)
    makeAssertion(topRow.children[2], 1.2, "along", 9)
    makeAssertion(topRow.children[2], 1.2, "height", 3)
    makeAssertion(topRow.children[2], 1.2, "across", 3)

    makeAssertion(container.children[2], 2, "height", 4)
    makeAssertion(container.children[2], 2, "along", 4)
    makeAssertion(container.children[2], 2, "width", 3)
    makeAssertion(container.children[2], 2, "across", 3)
end

local function test_crossGrow(verbose)
    local spec = CHERRY{
        name = "root",
        direction = "LEFT_TO_RIGHT",
        size = { FIXED(20), FIXED(6) },
    }{
        CHERRY{ name = "child1", size = { FIXED(5), GROW() }, backgroundColor = 1 }(),
        CHERRY{ name = "child2", size = { GROW(), FIXED(3) }, backgroundColor = 2 }(),
    }

    local container = Builder(spec)

    Cherry:layout()
    if verbose then visualize(container) end

    makeAssertion(container, 0, "width", 20)
    makeAssertion(container, 0, "along", 20)
    makeAssertion(container, 0, "height", 6)
    makeAssertion(container, 0, "across", 6)

    makeAssertion(container.children[1], 1, "width", 5)
    makeAssertion(container.children[1], 1, "along", 5)
    makeAssertion(container.children[1], 1, "height", 6)
    makeAssertion(container.children[1], 1, "across", 6)

    makeAssertion(container.children[2], 2, "width", 15)
    makeAssertion(container.children[2], 2, "along", 15)
    makeAssertion(container.children[2], 2, "height", 3)
    makeAssertion(container.children[2], 2, "across", 3)
end

local function test_fit(verbose)
    local spec = CHERRY{
        name = "root",
        direction = "TOP_TO_BOTTOM",
        size = { FIXED(20), FIXED(15) },
        padding = { top = 1, left = 1, right = 1, bottom = 1 },
        position = { 1, 1 },
        childGap = 1,
    }{
        CHERRY{
            name = "child1",
            direction = "LEFT_TO_RIGHT",
            size = { GROW(), FIT() },
            backgroundColor = 8,
            childGap = 1,
        }{
            CHERRY{
                name = "child1.1",
                size = { FIXED(9), FIXED(3) },
                backgroundColor = 4
            }(),
            CHERRY{
                name = "child1.2",
                size = { GROW(), FIXED(3) },
                backgroundColor = 4
            }()
        },
        CHERRY{
            name = "child2",
            size = { GROW(), FIXED(3) },
            backgroundColor = 2
        }(),
        CHERRY{
            name = "child3",
            size = { GROW(), GROW() },
            backgroundColor = 2
        }()
    }

    local container = Builder(spec)

    Cherry:layout()
    if verbose then visualize(container) end

    makeAssertion(container, 0, "height", 15)
    makeAssertion(container, 0, "along", 15)
    makeAssertion(container, 0, "width", 20)
    makeAssertion(container, 0, "across", 20)

    makeAssertion(container.children[1], 1, "width", 18)
    makeAssertion(container.children[1], 1, "along", 18)
    makeAssertion(container.children[1], 1, "height", 3)
    makeAssertion(container.children[1], 1, "across", 3)

    local topRow = container.children[1]
    makeAssertion(topRow.children[1], 1.1, "width", 9)
    makeAssertion(topRow.children[1], 1.1, "along", 9)
    makeAssertion(topRow.children[1], 1.1, "height", 3)
    makeAssertion(topRow.children[1], 1.1, "across", 3)

    makeAssertion(topRow.children[2], 1.2, "width", 8)
    makeAssertion(topRow.children[2], 1.2, "along", 8)
    makeAssertion(topRow.children[2], 1.2, "height", 3)
    makeAssertion(topRow.children[2], 1.2, "across", 3)

    makeAssertion(container.children[2], 2, "width", 18)
    makeAssertion(container.children[2], 2, "across", 18)
    makeAssertion(container.children[2], 2, "height", 3)
    makeAssertion(container.children[2], 2, "along", 3)

    makeAssertion(container.children[3], 3, "width", 18)
    makeAssertion(container.children[3], 3, "across", 18)
    makeAssertion(container.children[3], 3, "height", 5)
    makeAssertion(container.children[3], 3, "along", 5)
end

local function test_text(verbose)
    local spec = CHERRY{
        size = { FIT(), FIT() },
        padding = { top = 1, left = 1, right = 1, bottom = 1 },
        position = { 1, 1 },
        childGap = 1,
        backgroundColor = 512,
    }{
        CHERRY{
            text = "One Two Three Four",
            backgroundColor = 64,
        }(),
        CHERRY{
            size = { FIXED(6), FIXED(4) },
            backgroundColor = 16,
        }(),
        CHERRY{
            backgroundColor = 8,
            padding = { top = 1, left = 1, right = 1, bottom = 1 },
        }{
            CHERRY{
                text = "Five Six Seven Eight",
            }(),
        },
    }

    local container = Builder(spec)

    Cherry:layout()
    if verbose then visualize(container) end

    makeAssertion(container, 0, "width", 22)
    makeAssertion(container, 0, "along", 22)
    makeAssertion(container, 0, "height", 8)
    makeAssertion(container, 0, "across", 8)

    makeAssertion(container.children[1], 1, "width", 5)
    makeAssertion(container.children[1], 1, "along", 5)
    makeAssertion(container.children[1], 1, "height", 4)
    makeAssertion(container.children[1], 1, "across", 4)

    makeAssertion(container.children[2], 2, "width", 6)
    makeAssertion(container.children[2], 2, "along", 6)
    makeAssertion(container.children[2], 2, "height", 4)
    makeAssertion(container.children[2], 2, "across", 4)

    local fitContainer = container.children[3]

    makeAssertion(fitContainer, 3, "width", 7)
    makeAssertion(fitContainer, 3, "along", 7)
    makeAssertion(fitContainer, 3, "height", 6)
    makeAssertion(fitContainer, 3, "across", 6)

    makeAssertion(fitContainer.children[1], 3.1, "width", 7)
    makeAssertion(fitContainer.children[1], 3.1, "along", 7)
    makeAssertion(fitContainer.children[1], 3.1, "height", 6)
    makeAssertion(fitContainer.children[1], 3.1, "across", 6)
end

local function run()
    local tests = {
        ["Horizontal Grow"] = test_horizontalGrow,
        ["Vertical Grow"] = test_verticalGrow,
        ["Nested Grow"] = test_nestedGrow,
        ["Cross Grow"] = test_crossGrow,
        ["Fit"] = test_fit,
        ["Text"] = test_text,
    }
    local verbose = true
    for name, test in pairs(tests) do
        print("Running test:", name)
        test(verbose)
        print("\16 Passed\n")
        if verbose then
            repeat
                local _,key = os.pullEvent("key")
                sleep(0.1)
            until key == keys.enter
        end
    end
end

return run
