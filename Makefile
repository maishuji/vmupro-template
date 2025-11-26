PROJECT_NAME := $(shell basename $(CURDIR))
SDK_VERSION := 1.0.0
SDK_PATH := vmupro-sdk

# Determine deployment directory from metadata
APP_MODE := $(shell grep -o '"app_mode": [0-9]' metadata.json | grep -o '[0-9]')
ifeq ($(APP_MODE),1)
    DEPLOY_DIR := apps
else ifeq ($(APP_MODE),3)
    DEPLOY_DIR := games
else
    DEPLOY_DIR := apps
endif

.PHONY: all build deploy clean reset help sdk-update

all: build deploy

build:
	@echo "Building $(PROJECT_NAME)..."
	python3 $(SDK_PATH)/tools/packer/packer.py \
		--projectdir . \
		--appname $(PROJECT_NAME) \
		--meta metadata.json \
		--sdkversion $(SDK_VERSION) \
		--icon icon.bmp

deploy: build
	@echo "Deploying to $(DEPLOY_DIR)/..."
	python3 $(SDK_PATH)/tools/packer/send.py \
		--func send \
		--localfile $(PROJECT_NAME).vmupack \
		--remotefile $(DEPLOY_DIR)/$(PROJECT_NAME).vmupack \
		--exec \
		--monitor

sdk-update:
	@echo "Updating SDK submodule..."
	git submodule update --init --recursive

reset:
	@echo "Resetting device..."
	python3 $(SDK_PATH)/tools/packer/send.py --func reset

clean:
	rm -f *.vmupack

help:
	@echo "Available targets:"
	@echo "  build      - Package the application"
	@echo "  deploy     - Build and deploy to device"
	@echo "  reset      - Reset the VMU Pro device"
	@echo "  sdk-update - Update SDK submodule"
	@echo "  clean      - Remove built files"
