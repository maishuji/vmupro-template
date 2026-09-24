local Input = {}
Input.__index = Input

Input.buttons = {
    UP = 0,
    DOWN = 1,
    LEFT = 2,
    RIGHT = 3,
    A = 4,
    B = 5,
    POWER = 6,
    MODE = 7,
    FUNCTION = 8,
}

local function normalize_button(button)
    if type(button) == "number" then
        return button
    end

    if type(button) ~= "string" then
        return nil
    end

    return Input.buttons[string.upper(button)]
end

local function parse_frame(value, path, line_number)
    local frame = tonumber(value)
    if not frame or frame < 1 or frame % 1 ~= 0 then
        error(string.format("host input: invalid frame '%s' in %s:%d", value, path, line_number))
    end
    return frame
end

local function load_script(path)
    local file, open_error = io.open(path, "r")
    if not file then
        error(string.format("host input: cannot open '%s': %s", path, open_error or "unknown error"))
    end

    local events = {}
    for line_number, line in ipairs((function()
        local lines = {}
        for value in file:lines() do
            lines[#lines + 1] = value
        end
        return lines
    end)()) do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" and not trimmed:match("^#") then
            local frame_text, action, button_text = trimmed:match(
                "^frame%s+(%d+)%s*:%s*(%a+)%s+(%w+)%s*$"
            )
            if not frame_text then
                file:close()
                error(string.format("host input: invalid syntax in %s:%d", path, line_number))
            end

            local button = normalize_button(button_text)
            if button == nil then
                file:close()
                error(string.format("host input: unknown button '%s' in %s:%d", button_text, path, line_number))
            end

            action = string.lower(action)
            if action ~= "press" and action ~= "release" and action ~= "hold" then
                file:close()
                error(string.format("host input: unknown action '%s' in %s:%d", action, path, line_number))
            end

            local frame = parse_frame(frame_text, path, line_number)
            events[frame] = events[frame] or {}
            events[frame][#events[frame] + 1] = {
                action = action,
                button = button,
            }
        end
    end

    file:close()
    return events
end

function Input.new(options)
    options = options or {}

    local self = setmetatable({
        frame_number = 0,
        current = {},
        just_pressed = {},
        just_released = {},
        events = {},
    }, Input)

    if options.input_path then
        self.events = load_script(options.input_path)
    end

    if options.max_frames and options.max_frames > 0 then
        self.events[options.max_frames] = self.events[options.max_frames] or {}
        self.events[options.max_frames][#self.events[options.max_frames] + 1] = {
            action = "press",
            button = Input.buttons.MODE,
            synthetic = true,
        }
    end

    return self
end

function Input:read()
    self.frame_number = self.frame_number + 1
    self.just_pressed = {}
    self.just_released = {}

    for _, event in ipairs(self.events[self.frame_number] or {}) do
        local button = event.button
        if event.action == "press" then
            if not self.current[button] then
                self.just_pressed[button] = true
            end
            self.current[button] = true
        elseif event.action == "release" then
            if self.current[button] then
                self.just_released[button] = true
            end
            self.current[button] = false
        elseif event.action == "hold" then
            self.current[button] = true
        end
    end
end

function Input:pressed(button)
    return self.just_pressed[normalize_button(button)] == true
end

function Input:held(button)
    return self.current[normalize_button(button)] == true
end

function Input:released(button)
    return self.just_released[normalize_button(button)] == true
end

function Input:anythingHeld()
    for _, is_held in pairs(self.current) do
        if is_held then
            return true
        end
    end
    return false
end

function Input:confirmPressed()
    return self:pressed(Input.buttons.A)
end

function Input:confirmReleased()
    return self:released(Input.buttons.A)
end

function Input:dismissPressed()
    return self:pressed(Input.buttons.B)
end

function Input:dismissReleased()
    return self:released(Input.buttons.B)
end

function Input:frame()
    return self.frame_number
end

return Input
