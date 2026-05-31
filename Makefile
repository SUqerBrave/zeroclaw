IMAGE_NAME    = zeroclaw
IMAGE_TAG     = stagex
IMAGE_FAT_TAG = stagex-fat

.PHONY: help build build-fat app-build web-build rust-build extract extract-fat shell-debug clean

.DEFAULT_GOAL := help

help:
	@echo "ZeroClaw Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make              - Show this help message (default)"
	@echo "  make build        - Build the StageX container image"
	@echo "  make app-build    - Build the Web UI and embedded-web Rust backend"
	@echo "  make web-build    - Build the Web UI"
	@echo "  make rust-build   - Build the Rust backend with embedded-web"

build:
	podman build -t $(IMAGE_NAME):$(IMAGE_TAG) --target package -f Containerfile .

web-build:
	@echo "Building Web UI..."
	cd web && npm ci && npm run build

rust-build:
	@echo "Building Rust backend with embedded-web feature..."
	cargo build --features embedded-web

app-build: web-build rust-build
	@echo "Build complete."

build-fat:
	podman build -t $(IMAGE_NAME):$(IMAGE_FAT_TAG) --target package-fat -f Containerfile .

extract:
	@if ! podman image exists $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null; then \
		$(MAKE) build; \
	fi
	podman create --name zeroclaw-extract $(IMAGE_NAME):$(IMAGE_TAG)
	podman cp zeroclaw-extract:/usr/bin/zeroclaw .
	podman cp zeroclaw-extract:/usr/bin/zerocode .
	podman rm zeroclaw-extract
	ls -lh zeroclaw zerocode

extract-fat:
	@if ! podman image exists $(IMAGE_NAME):$(IMAGE_FAT_TAG) 2>/dev/null; then \
		$(MAKE) build-fat; \
	fi
	podman create --name zeroclaw-fat-extract $(IMAGE_NAME):$(IMAGE_FAT_TAG)
	podman cp zeroclaw-fat-extract:/usr/bin/zeroclaw .
	podman cp zeroclaw-fat-extract:/usr/bin/zerocode .
	podman rm zeroclaw-fat-extract
	mv zeroclaw zeroclaw-fat
	ls -lh zeroclaw-fat

shell-debug:
	podman run --rm -it \
		--entrypoint /bin/sh \
		docker.io/stagex/pallet-rust@sha256:2d90b9552412ee2c4fa2a13b489c2f28c044be7fb5d6a942bfd5a480a5c288fd

clean:
	-podman rmi $(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_NAME):$(IMAGE_FAT_TAG) 2>/dev/null
	rm -f zeroclaw zerocode zeroclaw-fat
