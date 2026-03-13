local Cherry = require("Cherry-v2")
local CHERRY = Cherry.Cherry
local render = Cherry.render
local calculate = Cherry.calculate

local monitor = peripheral.find("monitor")
monitor.setBackgroundColor(32768)
monitor.setTextScale(1)
monitor.clear()

term.redirect(monitor)

local width, height = monitor.getSize()

local tree = CHERRY("view", {
    style = {
        justifyContent = "space-between",
        padding = 1,
        width = "100%",
        height = "100%",
        paddingBottom = 2
    },
    children = {
        CHERRY("view", {
            style = {
                backgroundColor = 2,
                padding = 1,
                position = "absolute",
                top = 2,
                right = 2,
                zIndex = 1
            },
            children = {
                CHERRY("text", {
                    style = { color = 32768 },
                    children = "absolute"
                })
            }
        }),
        CHERRY("view", {
            style = { backgroundColor = 16, padding = 1 },
            children = CHERRY("text", {
                style = { color = 32768 },
                children = "Hello world!",
            })
        })
    }
})

render(calculate(tree))