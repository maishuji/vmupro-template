local HostRuntime = require("vmupro_mock")

return function()
    local runtime = HostRuntime.new({
        max_frames = 3,
        quiet = true,
    })

    _G.vmupro = runtime.vmupro
    _G.import = runtime.import

    local app_path = (HOST_PROJECT_ROOT or ".") .. "/src/main.lua"
    local application = assert(loadfile(app_path))
    local ok, application_error = xpcall(application, debug.traceback)
    assert(ok, application_error)

    local summary = runtime:summary()
    assert(summary.frames == 3)
    assert(summary.refreshed_frames == 4)
    assert(summary.log_count == 2)
    assert(runtime.logs[1].message == "Starting...")
    assert(runtime.logs[2].message == "Ending...")
end
