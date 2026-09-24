local source = debug.getinfo(1, "S").source
local script_path = source:sub(1, 1) == "@" and source:sub(2) or source
local script_directory = script_path:match("^(.*[/\\])") or "./"

package.path = script_directory .. "?.lua;" .. package.path

local HostRuntime = require("vmupro_mock")

local function usage()
    print([[Usage: lua tools/host-runner/run.lua [options]

Options:
  --projectdir PATH  Project root containing src/main.lua (default: .)
  --frames N         Maximum frame number before synthetic MODE press (default: 120)
  --input PATH       Scripted input file
  --quiet            Suppress application log output
  --help             Show this help

Input script format:
  frame 60: press MODE
  frame 90: release MODE
]])
end

local function require_value(args, index, option)
    local value = args[index + 1]
    if not value or value:sub(1, 2) == "--" then
        error(string.format("missing value for %s", option))
    end
    return value
end

local function parse_args(args)
    local options = {
        projectdir = ".",
        max_frames = 120,
        input_path = nil,
        quiet = false,
    }

    local index = 1
    while index <= #args do
        local option = args[index]
        if option == "--projectdir" then
            options.projectdir = require_value(args, index, option)
            index = index + 1
        elseif option == "--frames" then
            local value = tonumber(require_value(args, index, option))
            if not value or value < 1 or value % 1 ~= 0 then
                error("--frames must be a positive integer")
            end
            options.max_frames = value
            index = index + 1
        elseif option == "--input" then
            options.input_path = require_value(args, index, option)
            index = index + 1
        elseif option == "--quiet" then
            options.quiet = true
        elseif option == "--help" or option == "-h" then
            usage()
            os.exit(0)
        else
            error(string.format("unknown option '%s'", option))
        end
        index = index + 1
    end

    return options
end

local function join_path(directory, path)
    if path:sub(1, 1) == "/" or path:match("^%a:[/\\]") then
        return path
    end
    return directory:gsub("[/\\]+$", "") .. "/" .. path
end

local function run(options)
    local runtime = HostRuntime.new(options)
    _G.vmupro = runtime.vmupro
    _G.import = runtime.import

    local application_path = join_path(options.projectdir, "src/main.lua")
    local application, load_error = loadfile(application_path)
    if not application then
        error(string.format("host runner: cannot load '%s': %s", application_path, load_error))
    end

    local ok, application_error = xpcall(application, debug.traceback)
    local summary = runtime:summary()

    if not options.quiet then
        print(string.format(
            "Host run complete: %d input frame(s), %d refreshed frame(s), %d log message(s)",
            summary.frames,
            summary.refreshed_frames,
            summary.log_count
        ))
    end

    if not ok then
        error(application_error)
    end
end

local ok, error_message = xpcall(function()
    run(parse_args(arg))
end, debug.traceback)

if not ok then
    io.stderr:write(error_message .. "\n")
    os.exit(1)
end
