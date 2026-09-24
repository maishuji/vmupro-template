# VMU Pro Application Template

A template project for developing VMU Pro applications using the VMU Pro SDK.

## Project Structure

```
vmupro-template/
├── vmupro-sdk/              # Git submodule (SDK)
│   ├── sdk/api/            # API type definitions
│   ├── tools/              # Build tools (packer, send)
│   └── docs/               # Documentation
├── src/                    # Your application source
│   ├── main.lua           # Main application entry point
│   ├── libs/              # Your custom libraries
│   └── assets/            # Assets (images, data, etc.)
├── tools/host-runner/       # Hardware-free Lua host runner
├── tests/host/              # Deterministic host tests
├── .vscode/               # VS Code configuration
│   ├── tasks.json         # Build/deploy tasks
│   └── settings.json.template  # Lua workspace settings
├── metadata.json          # Application metadata
├── icon.bmp              # Application icon (76x76 BMP)
├── build.sh              # Build and deploy script
├── Makefile              # Make build system
├── .gitignore            # Git ignore rules
└── README.md             # This file
```

## Prerequisites

1. **Python 3** with pip
2. **Git**
3. **Virtual environment setup** (included in template)

Lua 5.3 is also required for the optional hardware-free host runner and deterministic tests.

The template includes a `.venv` directory with the required packages (Pillow, pyserial) already configured.

## Getting Started

### 1. Clone This Template

```bash
git clone --recursive <your-repo-url>
cd vmupro-template

# If you cloned without --recursive:
git submodule update --init --recursive
```

### 2. Verify Virtual Environment

The template includes a pre-configured virtual environment in `.venv/`:

```bash
# If needed, recreate the virtual environment
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install Pillow pyserial
```

The Makefile and build scripts automatically use `.venv/bin/python`.

### 3. Configure Your Application

Edit `metadata.json`:
```json
{
    "app_name": "Your App Name",
    "app_author": "Your Name",
    "app_version": "1.0.0",
    "app_mode": 1,  // 1 = Application, 3 = Game
    ...
}
```

### 4. Set Up VS Code (Optional)

If using VS Code, copy the settings template:
```bash
cp .vscode/settings.json.template .vscode/settings.json
```

Install the Lua extension for better development experience:
- [Lua Language Server](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)

## Development

### Write Your Application

Edit `src/main.lua` to implement your VMU Pro application. The template provides:
- `init()` - Initialize your application
- `update()` - Main update loop (~60 FPS)
- `cleanup()` - Clean up when exiting

### Available APIs

Import APIs at the top of your Lua files:
```lua
import "api/system"
import "api/display"
import "api/input"
import "api/storage"
-- See vmupro-sdk/sdk/api/ for all available APIs
```

## Hardware-free host testing

The host runner executes src/main.lua with a deterministic mock of the VMU Pro runtime, so you can exercise application logic without a connected device.

~~~bash
make host-run
make host-test
~~~

Use HOST_FRAMES to bound a run or HOST_INPUT to provide scripted button events:

~~~bash
make host-run HOST_FRAMES=300
make host-run HOST_INPUT=tests/host/input.script
~~~

See tools/host-runner/README.md for the supported mock API and limitations.

## Building & Deploying

### Using Make (Recommended)

```bash
# Build the application package
make build

# Build and deploy to device
make deploy

# Reset the device
make reset

# Update SDK submodule
make sdk-update

# Clean build artifacts
make clean

# Show all available targets
make help
```

### Using build.sh

```bash
# Build and deploy
./build.sh
```

### Using VS Code Tasks

Press `Ctrl+Shift+B` (or `Cmd+Shift+B` on Mac) to access build tasks:
- **Build with Make** (default)
- **Package Application**
- **Deploy App** - Deploy as application (app_mode: 1)
- **Deploy Game** - Deploy as game (app_mode: 3)
- **Deploy with Make**

## Application vs Game Mode

Set `app_mode` in `metadata.json`:
- **1** = Application - Deployed to `apps/` directory
- **3** = Game - Deployed to `games/` directory

The build system automatically detects the mode and deploys to the correct location.

## Creating Your Own Icon

Replace `icon.bmp` with a 76x76 pixel RGB BMP image. You can use tools like:
- GIMP
- Photoshop
- Python/PIL: `.venv/bin/python -c "from PIL import Image; img = Image.new('RGB', (76, 76), (255, 255, 255)); img.save('icon.bmp')"`
- Online BMP converters

## Updating the SDK

```bash
# Update to latest SDK version
git submodule update --remote vmupro-sdk
git add vmupro-sdk
git commit -m "Update VMU Pro SDK"
```

Or use Make:
```bash
make sdk-update
```

## Project Templates

### Switching to Game Template

To convert this to a game template:

1. Change `app_mode` to `3` in `metadata.json`
2. Update `src/main.lua` with game-specific logic
3. The build system will automatically deploy to `games/` directory

### Example Game Structure

```lua
-- Game state
local game_state = {
    running = true,
    score = 0,
    player = { x = 0, y = 0 }
}

function update()
    -- Handle input
    vmupro.input.read()
    
    -- Update game logic
    -- ...
    
    -- Render
    vmupro.graphics.clear(vmupro.graphics.BLACK)
    -- Draw game elements
    vmupro.graphics.refresh()
    
    return game_state.running
end
```

## Troubleshooting

### SDK Tools Not Found
```bash
# Ensure SDK submodule is initialized
git submodule update --init --recursive
```

### Python Package Errors
```bash
# Reinstall dependencies
pip install --upgrade Pillow pyserial
```

### Device Not Found
- Check USB connection
- Ensure VMU Pro is in development mode
- Check serial port permissions (Linux/Mac)

## Documentation

- [VMU Pro SDK Documentation](https://8bitmods.gitbook.io/vmupro-sdk/)
- [Development Guide](https://8bitmods.gitbook.io/vmupro-sdk/tools/development)
- API References in `vmupro-sdk/docs/`

## License

This template is provided as-is. Check the VMU Pro SDK license for SDK-specific terms.

## Contributing

Feel free to improve this template and submit pull requests!
