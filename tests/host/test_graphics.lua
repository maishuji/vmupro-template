local Graphics = require("graphics")

return function()
    local graphics = Graphics.new()

    assert(graphics.width == 240)
    assert(graphics.height == 240)

    graphics:clear(graphics.colors.BLACK)
    graphics:drawText("Hello", 10, 20, graphics.colors.WHITE, graphics.colors.BLACK)
    assert(graphics:commandCount() == 2)

    graphics:refresh()
    local frame = graphics:lastFrame()
    assert(frame ~= nil)
    assert(frame.number == 1)
    assert(#frame.commands == 2)
    assert(frame.commands[1].operation == "clear")
    assert(frame.commands[2].operation == "drawText")
    assert(frame.commands[2].text == "Hello")
    assert(graphics:commandCount() == 0)
end
