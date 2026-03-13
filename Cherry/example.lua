local Cherry = require("Cherry")
local CHERRY = Cherry.openUIElement
local Builder = Cherry.buildUIElement
local FIXED = Cherry.FIXED
local GROW = Cherry.GROW
local FIT = Cherry.FIT

local UnitTest = require("CherryTests")

local monitor = peripheral.find("monitor")
monitor.setBackgroundColor(32768)
monitor.setTextScale(1)
monitor.clear()

local width, height = monitor.getSize()

-- local spec = CHERRY{
--     name = "root",
--     direction = "TOP_TO_BOTTOM",
--     size = { FIXED(width), FIXED(height) },
--     padding = { top = 1, left = 1, right = 1, bottom = 1 },
--     position = { 1, 1 },
--     childGap = 1,
-- }{
--     CHERRY{
--         name = "child1",
--         size = { GROW(), FIT() },
--         direction = "LEFT_TO_RIGHT",
--         backgroundColor = 32,
--         childGap = 1,
--     }{
--         CHERRY{
--             name = "child1.1",
--             size = { FIXED(9), FIT() },
--             backgroundColor = 64,
--             pressedColor = 4,
--             text = "this is a test.",
--             onClick = function(self)
--                 print("Clicked!")
--             end
--         }(),
--         CHERRY{
--             name = "child1.2",
--             size = { GROW(), FIXED(3) },
--             backgroundColor = 128
--         }()
--     },
--     CHERRY{
--         name = "child2",
--         size = { GROW(), FIXED(3) },
--         backgroundColor = 256
--     }(),
--     CHERRY{
--         name = "child3",
--         size = { GROW(), FIXED(50) },
--         backgroundColor = 512,
--         padding = { top = 1, left = 1, right = 1, bottom = 1 },
--         childGap = 1,
--     }{
--         CHERRY{ name = "child3.1", size = { GROW(), FIXED(2) } }(),
--         CHERRY{ name = "child3.2", size = { GROW(), FIXED(2) } }(),
--         CHERRY{ name = "child3.3", size = { GROW(), FIXED(2) } }(),
--         CHERRY{ name = "child3.4", size = { GROW(), FIXED(2) } }(),
--     }
-- }

local spec = CHERRY{
    size = { FIXED(width), FIXED(height) },
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
            backgroundColor = 8,
        }(),
    },
}

local ui = Builder(spec)

UnitTest()

Cherry:layout()

while true do
    ui:draw(monitor)

    local event = { os.pullEvent() }
    ui:handleEvent(event)
end

