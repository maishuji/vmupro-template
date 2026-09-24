# Repository Instructions

## Project scope

This repository is a VMU Pro Lua application template. Keep the device packaging and deployment path stable while adding development conveniences such as the host runner.

The host runner is development-only. Host mocks, tests, logs, and generated output must not be included in `metadata.json` resources or `.vmupack` artifacts.

## Working conventions

- Make small, reviewable changes grouped by one logical step.
- Preserve existing user changes and inspect `git status` before committing.
- Use `apply_patch` for source edits.
- Prefer deterministic, headless tests for CI.
- Document differences between host behavior and VMU Pro firmware behavior.
- Do not add QEMU, ESP-IDF, serial-device, or GUI dependencies to the Lua host-test path.

## Commit conventions

Use Conventional Commits for every commit:

```text
<type>(<optional scope>): <imperative summary>
```

Use a body when the change needs context, implementation detail, or an explicit limitation. Recommended types include:

- `feat`: add user-facing functionality
- `fix`: correct faulty behavior
- `test`: add or change tests without changing production behavior
- `docs`: documentation or repository instructions
- `build`: build-system or dependency changes
- `ci`: continuous-integration changes
- `refactor`: behavior-preserving code restructuring

Examples:

```text
feat(host-runner): add deterministic Lua application runner
test(host-runner): cover scripted input and lifecycle shutdown
ci: run headless host tests
```

Commit each implementation step separately. Before committing, run the relevant checks and confirm the staged file list.

## Host runner expectations

- `make host-run` should run the sample application without hardware.
- `make host-test` must be deterministic and bounded.
- The default host runtime should not sleep in real time.
- A maximum frame count must prevent applications from hanging CI.
- Unsupported APIs should fail clearly or be reported as unsupported; they must not silently claim hardware fidelity.
- Keep the host API surface aligned with the SDK stubs in `vmupro-sdk/sdk/api/`.

## Validation

At minimum, validate:

```text
make host-test
make build
```

When Lua is unavailable locally, use the CI workflow or install the project-supported Lua interpreter before claiming runtime validation.

