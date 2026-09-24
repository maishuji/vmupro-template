local Input = require("input")

return function()
    local input_path = (HOST_PROJECT_ROOT or ".") .. "/tests/host/input.script"
    local input = Input.new({input_path = input_path})

    assert(input:frame() == 0)

    input:read()
    assert(input:frame() == 1)
    assert(input:pressed(Input.buttons.A))
    assert(input:held(Input.buttons.A))

    input:read()
    assert(input:frame() == 2)
    assert(not input:pressed(Input.buttons.A))
    assert(input:held(Input.buttons.A))

    input:read()
    assert(input:frame() == 3)
    assert(input:released(Input.buttons.A))
    assert(not input:held(Input.buttons.A))

    local bounded = Input.new({max_frames = 2})
    bounded:read()
    assert(not bounded:pressed(Input.buttons.MODE))
    bounded:read()
    assert(bounded:pressed(Input.buttons.MODE))
end
