LLAMA_SWAP_VERSION=v182
LLAMA_CPP_VERSION=master

LLAMA_CPP_INCLUDE_PRS=

DOCKER_CMD ?= podman

ROCM_ARCHES ?= gfx1151,gfx1200,gfx1201,gfx1100,gfx1102,gfx1030,gfx1031,gfx1032

build: build-vulkan build-rocm build-zluda

.PHONY: build-vulkan
build-vulkan:
	$(DOCKER_CMD) build --target=llama-swap-vulkan-final --tag quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION) --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg LLAMA_CPP_VERSION=$(LLAMA_CPP_VERSION) --build-arg LLAMA_CPP_INCLUDE_PRS="$(LLAMA_CPP_INCLUDE_PRS)" .
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION) quay.io/wvdschel/llama-swap:latest

.PHONY: build-rocm
build-rocm:
	$(DOCKER_CMD) build --target=llama-swap-rocm-final --tag quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION)-rocm --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg ROCM_ARCH="$(ROCM_ARCHES)"  --build-arg LLAMA_CPP_VERSION=$(LLAMA_CPP_VERSION) --build-arg LLAMA_CPP_INCLUDE_PRS="$(LLAMA_CPP_INCLUDE_PRS)" .
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION)-rocm quay.io/wvdschel/llama-swap:latest-rocm
	$(DOCKER_CMD) build --target=llama-swap-rocm-igpu-final --tag quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION)-rocm-igpu --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg ROCM_ARCH="$(ROCM_ARCHES)"  --build-arg LLAMA_CPP_VERSION=$(LLAMA_CPP_VERSION) --build-arg LLAMA_CPP_INCLUDE_PRS="$(LLAMA_CPP_INCLUDE_PRS)" .
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION)-rocm-igpu quay.io/wvdschel/llama-swap:latest-rocm-igpu

.PHONY: build-zluda
build-zluda:
	$(DOCKER_CMD) build --target=llama-swap-zluda-final --tag quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION)-zluda --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg ROCM_ARCH="$(ROCM_ARCHES)"  --build-arg LLAMA_CPP_VERSION=$(LLAMA_CPP_VERSION) --build-arg LLAMA_CPP_INCLUDE_PRS="$(LLAMA_CPP_INCLUDE_PRS)" .
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION)-zluda quay.io/wvdschel/llama-swap:latest-zluda

.PHONY: publish
publish: build
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION)
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION)-amdvlk
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION)-rocm-igpu
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION)-rocm
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap:$(LLAMA_SWAP_VERSION)-zluda

.PHONY: publish-latest
publish-latest: publish
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap:latest
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap:latest-amdvlk
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap:latest-rocm-igpu
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap:latest-rocm
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap:latest-zluda
