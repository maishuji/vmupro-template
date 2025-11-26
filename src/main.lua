-- My VMU Pro Application
import "api/system"
import "api/display"
import "api/input"

function init()
    vmupro.system.log(vmupro.system.LOG_INFO, "App", "Starting...")
    -- TODO: Initialize your application state here
    return true
end

function update()
    vmupro.graphics.clear(vmupro.graphics.BLACK)

    -- TODO: Handle input
    vmupro.input.read()

    -- TODO: Update application logic here

    -- TODO: Draw your application UI here
    vmupro.graphics.drawText("My App", 50, 20, vmupro.graphics.WHITE, vmupro.graphics.BLACK)
    vmupro.graphics.drawText("Press MODE to exit", 20, 200, vmupro.graphics.GREY, vmupro.graphics.BLACK)

    vmupro.graphics.refresh()

    -- Handle exit
    if vmupro.input.pressed(vmupro.input.MODE) then
        return false
    end

    return true
end

function cleanup()
    vmupro.system.log(vmupro.system.LOG_INFO, "App", "Ending...")
    -- TODO: Clean up resources here
    vmupro.graphics.clear(vmupro.graphics.BLACK)
    vmupro.graphics.refresh()
end

-- Main execution
if not init() then
    return
end

while update() do
    vmupro.system.delayMs(16) -- ~60 FPS
end

cleanup()
