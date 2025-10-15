LLAMA_SWAP_VERSION=v165
LLAMA_CPP_VERSION=master

LLAMA_CPP_INCLUDE_PRS=
# Seed thought web UI - no longer applies cleanly
#LLAMA_CPP_INCLUDE_PRS+=15820
# Qwen tool calling
#LLAMA_CPP_INCLUDE_PRS+=15161,15162
# GLM 4.5 Air tool calling
#LLAMA_CPP_INCLUDE_PRS+=15904

DOCKER_CMD ?= podman

ROCM_ARCHES ?= gfx1151,gfx1200,gfx1201,gfx1100,gfx1102,gfx1030,gfx1031,gfx1032

build: build-amdvlk build-vulkan build-rocm

.PHONY: build-amdvlk
build-amdvlk:
	$(DOCKER_CMD) build --target=llama-swap-amdvlk-final --tag quay.io/wvdschel/llama-swap-amdvlk:$(LLAMA_SWAP_VERSION) --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg LLAMA_CPP_VERSION=$(LLAMA_CPP_VERSION) --build-arg LLAMA_CPP_INCLUDE_PRS="$(LLAMA_CPP_INCLUDE_PRS)" .
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap-amdvlk:$(LLAMA_SWAP_VERSION) quay.io/wvdschel/llama-swap-amdvlk:latest

.PHONY: build-vulkan
build-vulkan:
	$(DOCKER_CMD) build --target=llama-swap-vulkan-final --tag quay.io/wvdschel/llama-swap-vulkan:$(LLAMA_SWAP_VERSION) --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg LLAMA_CPP_VERSION=$(LLAMA_CPP_VERSION) --build-arg LLAMA_CPP_INCLUDE_PRS="$(LLAMA_CPP_INCLUDE_PRS)" .
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap-vulkan:$(LLAMA_SWAP_VERSION) quay.io/wvdschel/llama-swap-vulkan:latest

.PHONY: build-rocm
build-rocm:
	$(DOCKER_CMD) build --target=llama-swap-rocm-final --tag quay.io/wvdschel/llama-swap-rocm:$(LLAMA_SWAP_VERSION) --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg ROCM_ARCH="$*"  --build-arg LLAMA_CPP_VERSION=$(LLAMA_CPP_VERSION) --build-arg LLAMA_CPP_INCLUDE_PRS="$(LLAMA_CPP_INCLUDE_PRS)" .
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap-rocm:$(LLAMA_SWAP_VERSION) quay.io/wvdschel/llama-swap-rocm:latest

.PHONY: publish
publish: build
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-amdvlk:$(LLAMA_SWAP_VERSION)
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-vulkan:$(LLAMA_SWAP_VERSION)
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-rocm:$(LLAMA_SWAP_VERSION)

.PHONY: publish-latest
publish-latest: publish
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-amdvlk:latest
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-vulkan:latest
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-rocm:latest
