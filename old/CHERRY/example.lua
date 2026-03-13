local Cherry = require("Cherry")
local CHERRY = Cherry.CHERRY
local FIXED = Cherry.FIXED
local GROW = Cherry.GROW
local FIT = Cherry.FIT

local monitor = peripheral.find("monitor")
monitor.setBackgroundColor(32768)
monitor.setTextScale(1)
monitor.clear()

local width, height = monitor.getSize()

local container = CHERRY{
    direction = "TOP_TO_BOTTOM",
    size = { FIXED(width), FIXED(height) },
    padding = { top = 1, left = 1, right = 1, bottom = 1 },
    position = { 1, 1 },
    childGap = 1,
    children = {
        {
            size = { FIT(), FIT() },
            backgroundColor = 8,
            children = {
                {
                    size = { FIXED(9), FIXED(3) },
                    backgroundColor = 4
                }
            }
        },
        {
            size = { FIXED(3), GROW() },
            backgroundColor = 2
        }
    }
}

container:draw(monitor)