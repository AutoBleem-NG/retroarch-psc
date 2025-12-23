# Makefile for RetroArch ARM cross-compilation
# Copyright (C) 2024-2025 AutoBleem-NG
# Licensed under GPL-3.0 - See LICENSE file

IMAGE_NAME := retroarch-psc
OUTPUT_DIR := retroarch_bin

.PHONY: all build extract clean shell

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

# Clean everything
clean:
	@rm -rf $(OUTPUT_DIR)
	@docker rmi $(IMAGE_NAME) 2>/dev/null || true
	@echo "Cleaned"
