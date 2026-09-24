# Host Runner Plan

## Objective

Add a PC-side host runner for VMU Pro Lua applications so the project can be developed and tested without a connected VMU Pro device.

The runner should execute the same application source used for packaging, provide a mock implementation of the VMU Pro Lua API, and support deterministic automated tests.

This is a development and testing tool only. It must not change the `.vmupack` format or add host-only files to deployed packages.

## Scope

### In scope

- Run `src/main.lua` on a development machine.
- Provide host implementations for the APIs used by the template:
  - `vmupro.system`
  - `vmupro.graphics`
  - `vmupro.input`
- Support deterministic frame execution for CI.
- Capture logs, input events, and drawing commands.
- Add Makefile targets for host execution and tests.
- Document the host runner and its limitations.
- Add an optional graphical backend after the headless runner is stable.

### Out of scope

- Emulating the ESP32-S3 or VMU Pro firmware.
- Reproducing exact device timing or memory limits.
- Testing the real serial deployment path.
- Including host-runner code in `metadata.json` resources.
- Guaranteeing hardware-accurate audio, display, or storage behavior.

## Proposed layout

```text
tools/
└── host-runner/
    ├── README.md
    ├── run.lua              # Host entry point/bootstrap
    ├── vmupro_mock.lua      # Mock VMU Pro API
    ├── input.lua            # Scripted and interactive input providers
    └── graphics.lua         # Headless framebuffer/command recorder

tests/
└── host/
    ├── test_smoke.lua
    ├── test_input.lua
    └── test_graphics.lua
```

The exact implementation language can be revisited after the headless API is defined. The first version should prefer the existing Lua runtime and avoid introducing a large native dependency.

## Runtime design

### Application loading

The host runner should load the existing `src/main.lua` without requiring application changes.

The VMU Pro source uses calls such as:

```lua
import "api/system"
import "api/display"
import "api/input"
```

The host bootstrap must provide an `import(name)` function. It should map these imports to host-compatible API modules or safely load the SDK stubs while supplying host implementations for the `vmupro` functions.

### Frame lifecycle

The runner should preserve the application lifecycle:

1. Load the application.
2. Call `init()`.
3. Repeatedly call `update()`.
4. Stop when `update()` returns `false`.
5. Call `cleanup()`.

The runner must support a maximum frame count so applications that never exit cannot hang CI.

Example interface:

```text
make host-run HOST_FRAMES=300
make host-test
```

### System mock

Implement the minimum system surface required by the template:

- `LOG_INFO`, `LOG_WARNING`, and `LOG_ERROR` constants.
- `log(level, tag, message)` routed to stdout or a structured test log.
- `delayMs(ms)` implemented as deterministic simulated time by default.
- A host clock accessor if required by future tests.

The default test mode should not sleep in real time.

### Input mock

Implement:

- `read()` to advance or apply the current input state.
- `pressed(button)` for edge-triggered button checks.
- The button constants used by the SDK, starting with `MODE`.

Input providers should include:

- A deterministic scripted provider for tests.
- A simple interactive provider for the graphical backend.

Example scripted input:

```text
frame 60: press MODE
```

The input contract must distinguish pressed, held, and released states even if the first application only needs `pressed()`.

### Graphics mock

The first backend should be headless and deterministic.

Implement the operations used by the template:

- `clear(color)`
- `drawText(text, x, y, foreground, background)`
- `refresh()`
- Required color constants such as `BLACK`, `WHITE`, and `GREY`.

The headless backend should maintain a virtual framebuffer or command list and expose it to tests. It should also be able to emit a compact frame summary for debugging.

The framebuffer dimensions and color format should be configurable, with defaults matching the VMU Pro SDK documentation once confirmed.

## Phases

### Phase 0: Confirm the host contract

- Inventory the APIs used by `src/main.lua` and the SDK stubs.
- Confirm the Lua interpreter version supported by the project.
- Decide whether the host runner loads SDK stub files, replaces them, or intercepts imports.
- Define the input-state and frame-timing semantics.
- Define the minimum framebuffer dimensions and color representation.

Deliverable: a short host API contract and a list of supported versus unsupported VMU Pro APIs.

### Phase 1: Headless smoke runner

- Add the host-runner directory.
- Implement the import bootstrap.
- Implement the minimum system, input, and graphics mocks.
- Add a maximum-frame option.
- Run the existing `src/main.lua` successfully on the host.
- Confirm that `cleanup()` executes when the scripted MODE button is pressed.

Deliverable: `make host-run` executes the existing template application without hardware.

### Phase 2: Deterministic test harness

- Add scripted input sequences.
- Add assertions for lifecycle calls and exit behavior.
- Add graphics command/framebuffer assertions.
- Add log capture and error propagation.
- Ensure test runs do not depend on wall-clock timing.
- Add a CI job that runs the host tests with a standard Lua installation.

Deliverable: `make host-test` runs reliably in local development and CI.

### Phase 3: Developer usability

- Add command-line options for frame count, input script, log level, and backend.
- Add clear diagnostics for unsupported APIs.
- Add a host-runner README with examples.
- Add VS Code tasks for host run and host tests.
- Update the root README with the hardware-free workflow.

Deliverable: a new contributor can run and test the sample application without connecting a device.

### Phase 4: Optional graphical backend

- Select a lightweight host window/input technology only after the headless contract is stable.
- Render the virtual framebuffer or graphics command list.
- Map keyboard keys to VMU Pro buttons.
- Add pause, frame stepping, and screenshot capture if useful.
- Keep the headless backend as the canonical CI backend.

Deliverable: `make host-run` can optionally open a desktop preview window while preserving deterministic headless execution.

### Phase 5: SDK/API expansion

- Add mocks for additional APIs as applications need them.
- Add storage backed by a temporary host directory.
- Add audio as a command/event sink before attempting real playback.
- Add explicit capability reporting so applications/tests know what is simulated.
- Add conformance tests shared by the host mock and hardware smoke tests where possible.

Deliverable: the host runner supports the subset of the SDK that provides meaningful development value.

## Makefile targets

Proposed targets:

```make
host-run:
        # Run the sample application with the host backend

host-test:
        # Run deterministic Lua host tests

host-clean:
        # Remove host-only generated state and temporary output
```

The existing `build`, `deploy`, `reset`, and `clean` targets must retain their device-oriented behavior.

## CI strategy

The CI workflow should gain a separate host-test step or job:

1. Install the supported Lua interpreter.
2. Run `make host-test` in headless mode.
3. Validate that the test process exits on failure.
4. Keep package creation as a separate existing check.

The graphical backend should not be required for CI initially.

## Acceptance criteria

- The current sample application runs on a PC without a VMU Pro connected.
- The host runner exits deterministically after a configured frame limit.
- A scripted MODE press causes the sample application to exit normally.
- Logs and graphics operations can be inspected by tests.
- Host tests pass in CI without serial, USB, ESP-IDF, or QEMU dependencies.
- `make build` still produces the same Lua package path as before.
- Host-only files are not included in the packaged application.
- Unsupported VMU Pro APIs fail clearly rather than silently producing misleading behavior.

## Main risks

- The SDK's `import` behavior may differ from stock Lua module loading.
- The real firmware may have timing or API semantics that are not obvious from the stubs.
- A graphical backend can introduce more dependency and platform complexity than the initial value justifies.
- A host mock can create false confidence if hardware-specific behavior is not clearly documented.

## Recommended first implementation

Start with Phases 0–2 only: a headless runner, deterministic input, a minimal graphics command recorder, and CI tests. Do not begin with QEMU or a desktop renderer. Once the application contract is proven, add a graphical backend based on actual development needs.
