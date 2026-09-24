local Graphics = require("graphics")
local Input = require("input")

local HostRuntime = {}
HostRuntime.__index = HostRuntime

local supported_imports = {
    ["api/system"] = true,
    ["api/display"] = true,
    ["api/input"] = true,
}

local log_names = {
    [0] = "ERROR",
    [1] = "WARN",
    [2] = "INFO",
    [3] = "DEBUG",
}

local function append_log(logs, level, tag, message)
    logs[#logs + 1] = {
        level = level,
        level_name = log_names[level] or tostring(level),
        tag = tostring(tag),
        message = tostring(message),
    }
end

function HostRuntime.new(options)
    options = options or {}

    local input = Input.new(options)
    local graphics = Graphics.new(options)
    local logs = {}
    local current_time_us = 0

    local runtime = setmetatable({
        input = input,
        graphics = graphics,
        logs = logs,
        quiet = options.quiet == true,
        vmupro = nil,
    }, HostRuntime)

    local system = {
        LOG_ERROR = 0,
        LOG_WARN = 1,
        LOG_WARNING = 1,
        LOG_INFO = 2,
        LOG_DEBUG = 3,
    }

    function system.log(level, tag, message)
        append_log(logs, level, tag, message)
        if not runtime.quiet then
            io.stdout:write(string.format("[%s] %s: %s\n", log_names[level] or tostring(level), tag, message))
        end
    end

    function system.delayMs(milliseconds)
        current_time_us = current_time_us + (tonumber(milliseconds) or 0) * 1000
    end

    function system.delayUs(microseconds)
        current_time_us = current_time_us + (tonumber(microseconds) or 0)
    end

    function system.sleep(milliseconds)
        system.delayMs(milliseconds)
    end

    function system.getTimeUs()
        return current_time_us
    end

    local vmupro = {
        system = system,
        input = {
            read = function() return input:read() end,
            pressed = function(button) return input:pressed(button) end,
            held = function(button) return input:held(button) end,
            released = function(button) return input:released(button) end,
            anythingHeld = function() return input:anythingHeld() end,
            confirmPressed = function() return input:confirmPressed() end,
            confirmReleased = function() return input:confirmReleased() end,
            dismissPressed = function() return input:dismissPressed() end,
            dismissReleased = function() return input:dismissReleased() end,
        },
        graphics = {
            clear = function(color) return graphics:clear(color) end,
            drawText = function(text, x, y, color, background_color)
                return graphics:drawText(text, x, y, color, background_color)
            end,
            refresh = function() return graphics:refresh() end,
        },
    }

    for name, value in pairs(Input.buttons) do
        vmupro.input[name] = value
    end
    for name, value in pairs(Graphics.colors) do
        vmupro.graphics[name] = value
    end

    runtime.vmupro = vmupro
    runtime.import = function(name)
        if not supported_imports[name] then
            error(string.format("host runner: unsupported import '%s'", tostring(name)))
        end
        return true
    end

    return runtime
end

function HostRuntime:summary()
    return {
        frames = self.input:frame(),
        refreshed_frames = self.graphics:frameCount(),
        log_count = #self.logs,
    }
end

return HostRuntime
