local Graphics = {}
Graphics.__index = Graphics

Graphics.colors = {
    RED = 0xF800,
    ORANGE = 0xFBA0,
    YELLOW = 0xFF80,
    YELLOWGREEN = 0x7F80,
    GREEN = 0x0500,
    BLUE = 0x045F,
    NAVY = 0x000C,
    VIOLET = 0x781F,
    MAGENTA = 0x780D,
    GREY = 0xB5B6,
    BLACK = 0x0000,
    WHITE = 0xFFFF,
    VMUGREEN = 0x6CD2,
    VMUINK = 0x288A,
}

local function copy_command(command)
    local result = {}
    for key, value in pairs(command) do
        result[key] = value
    end
    return result
end

local function copy_commands(commands)
    local result = {}
    for index, command in ipairs(commands) do
        result[index] = copy_command(command)
    end
    return result
end

function Graphics.new(options)
    options = options or {}

    return setmetatable({
        width = options.width or 240,
        height = options.height or 240,
        frame_number = 0,
        commands = {},
        frames = {},
        last_frame = nil,
    }, Graphics)
end

function Graphics:clear(color)
    self.commands[#self.commands + 1] = {
        operation = "clear",
        color = color == nil and self.colors.BLACK or color,
    }
end

function Graphics:drawText(text, x, y, color, background_color)
    self.commands[#self.commands + 1] = {
        operation = "drawText",
        text = tostring(text),
        x = x,
        y = y,
        color = color,
        background_color = background_color,
    }
end

function Graphics:refresh()
    self.frame_number = self.frame_number + 1
    self.last_frame = {
        number = self.frame_number,
        commands = copy_commands(self.commands),
    }
    self.frames[#self.frames + 1] = self.last_frame
    self.commands = {}
end

function Graphics:frameCount()
    return self.frame_number
end

function Graphics:lastFrame()
    return self.last_frame
end

function Graphics:commandCount()
    return #self.commands
end

return Graphics
