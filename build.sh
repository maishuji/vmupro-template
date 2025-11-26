#!/bin/bash
# build.sh - Build script using VMU Pro SDK submodule

PROJECT_NAME=$(basename "$(pwd)")
SDK_VERSION="1.0.0"
SDK_PATH="vmupro-sdk"

# Ensure SDK submodule is initialized
if [ ! -f "$SDK_PATH/tools/packer/packer.py" ]; then
    echo "SDK submodule not found. Initializing..."
    git submodule update --init --recursive
fi

echo "Building $PROJECT_NAME..."

# Check metadata for app type
if grep -q '"app_mode": 1' metadata.json; then
    DEPLOY_DIR="apps"
    echo "Detected: Application (app_mode: 1)"
elif grep -q '"app_mode": 3' metadata.json; then
    DEPLOY_DIR="games"
    echo "Detected: Game (app_mode: 3)"
else
    echo "Warning: Unknown app_mode, defaulting to apps/"
    DEPLOY_DIR="apps"
fi

# Package application using SDK tools
echo "Packaging with SDK..."
python3 "$SDK_PATH/tools/packer/packer.py" \
    --projectdir . \
    --appname "$PROJECT_NAME" \
    --meta metadata.json \
    --sdkversion "$SDK_VERSION" \
    --icon icon.bmp

if [ $? -ne 0 ]; then
    echo "✗ Packaging failed"
    exit 1
fi

# Deploy to device using SDK tools
echo "Deploying to $DEPLOY_DIR/..."
python3 "$SDK_PATH/tools/packer/send.py" \
    --func send \
    --localfile "$PROJECT_NAME.vmupack" \
    --remotefile "$DEPLOY_DIR/$PROJECT_NAME.vmupack" \
    --exec \
    --monitor

if [ $? -eq 0 ]; then
    echo "✓ Successfully deployed $PROJECT_NAME"
else
    echo "✗ Deployment failed"
    exit 1
fi
