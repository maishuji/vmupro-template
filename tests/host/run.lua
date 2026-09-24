local source = debug.getinfo(1, "S").source
local test_path = source:sub(1, 1) == "@" and source:sub(2) or source
local test_directory = test_path:match("^(.*[/\\])") or "./"
local host_directory = test_directory .. "../../tools/host-runner/"

package.path = test_directory .. "?.lua;" .. host_directory .. "?.lua;" .. package.path

_G.HOST_PROJECT_ROOT = test_directory .. "../.."

local tests = {
    "test_input",
    "test_graphics",
    "test_smoke",
}

local failures = 0
for _, test_name in ipairs(tests) do
    io.write(string.format("%s ... ", test_name))
    local ok, test_error = xpcall(function()
        require(test_name)()
    end, debug.traceback)

    if ok then
        print("ok")
    else
        print("failed")
        io.stderr:write(test_error .. "\n")
        failures = failures + 1
    end
end

if failures > 0 then
    error(string.format("%d host test(s) failed", failures))
end

print(string.format("%d host test(s) passed", #tests))
