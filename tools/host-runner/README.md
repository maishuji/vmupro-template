# VMU Pro Host Runner

The host runner executes the Lua application on a PC with a deterministic mock of the VMU Pro runtime. It is intended for development and CI when a physical VMU Pro is not connected.

## Quick start

Install a Lua 5.3 interpreter, then run:

~~~bash
make host-run
~~~

The runner executes src/main.lua and automatically sends a synthetic MODE press at the frame limit so applications that do not receive input cannot run forever.

Useful options:

~~~bash
make host-run HOST_FRAMES=300
make host-run HOST_INPUT=tests/host/input.script
make host-run LUA=lua5.4
make host-test
~~~

The runner can also be called directly:

~~~bash
lua5.3 tools/host-runner/run.lua --projectdir . --frames 120
~~~

## Input scripts

Input scripts use one event per line:

~~~text
frame 60: press MODE
frame 90: release MODE
~~~

Supported actions are press, hold, and release. Supported buttons initially include UP, DOWN, LEFT, RIGHT, A, B, POWER, MODE, and FUNCTION.

## Current host API

The headless runtime currently provides:

- vmupro.system: logging, simulated delays, and simulated time.
- vmupro.input: frame updates and pressed/held/released button state.
- vmupro.graphics: RGB565 colors, clear, drawText, and refresh.
- import: validation for the API imports used by the template.

Graphics operations are recorded as deterministic commands. The current framebuffer contract is 240x240 pixels, matching the SDK documentation.

## Limitations

The host runner is not a VMU Pro firmware emulator. It does not reproduce device timing, memory limits, audio hardware, SD-card behavior, or serial deployment. Hardware testing is still required for final integration validation.

Unsupported API imports fail clearly so that a host test cannot accidentally appear hardware-accurate.
