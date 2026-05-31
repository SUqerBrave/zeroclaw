.PHONY: help build web-build rust-build

.DEFAULT_GOAL := help

help:
	@echo "ZeroClaw Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make         - Show this help message (default)"
	@echo "  make help    - Show this help message"
	@echo "  make build   - Build the Web UI and compile the Rust backend with embedded-web"

web-build:
	@echo "Building Web UI..."
	cd web && npm ci && npm run build

rust-build:
	@echo "Building Rust backend with embedded-web feature..."
	cargo build --features embedded-web

build: web-build rust-build
	@echo "Build complete."
