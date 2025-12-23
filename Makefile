# Makefile for RetroArch ARM cross-compilation
# Copyright (C) 2024-2025 AutoBleem-NG
# Licensed under GPL-3.0 - See LICENSE file

IMAGE_NAME := retroarch-psc
OUTPUT_DIR := retroarch_bin

# Version: RetroArch version from Dockerfile + build number from git tag
RA_VERSION := $(shell grep -oP 'ARG RETROARCH_VERSION=\K[^\s]+' Dockerfile)
BUILD_NUM := $(shell git describe --tags --abbrev=0 2>/dev/null | grep -oP '\d+$$' || echo "1")
VERSION := $(RA_VERSION)-$(BUILD_NUM)

.PHONY: all build extract package release clean shell version

# Default target
all: build extract

# Build the Docker image
build:
	@echo "Building RetroArch for PSC..."
	docker build -t $(IMAGE_NAME) .

# Build without cache
rebuild:
	@echo "Building RetroArch for PSC (no cache)..."
	docker build --no-cache -t $(IMAGE_NAME) .

# Extract binary from image
extract:
	@mkdir -p $(OUTPUT_DIR)
	@id=$$(docker create $(IMAGE_NAME)) && \
	docker cp $$id:/build/output/. $(OUTPUT_DIR)/ && \
	docker rm $$id > /dev/null
	@echo "Binary extracted to $(OUTPUT_DIR)/"
	@ls -lh $(OUTPUT_DIR)/

# Interactive shell for debugging
shell:
	docker run --rm -it $(IMAGE_NAME) /bin/bash

# Package binary for release
package: extract
	@cd $(OUTPUT_DIR) && zip retroarch-psc-$(VERSION).zip retroarch
	@echo "Created $(OUTPUT_DIR)/retroarch-psc-$(VERSION).zip"

# Full release: build + package
release: build package

# Show version info
version:
	@echo "RetroArch: $(RA_VERSION)"
	@echo "Build: $(BUILD_NUM)"
	@echo "Package: retroarch-psc-$(VERSION).zip"

# Clean everything
clean:
	@rm -rf $(OUTPUT_DIR)
	@docker rmi $(IMAGE_NAME) 2>/dev/null || true
	@echo "Cleaned"
