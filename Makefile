LLAMA_SWAP_VERSION=v164
LLAMA_CPP_VERSION=master

LLAMA_CPP_INCLUDE_PRS=
# Seed thought web UI - no longer applies cleanly
#LLAMA_CPP_INCLUDE_PRS+=15820
# Qwen tool calling
#LLAMA_CPP_INCLUDE_PRS+=15161,15162
# GLM 4.5 Air tool calling
#LLAMA_CPP_INCLUDE_PRS+=15904

DOCKER_CMD ?= podman

build: build-amdvlk build-vulkan

.PHONY: build-amdvlk
build-amdvlk:
	$(DOCKER_CMD) build --target=llama-swap-amdvlk --tag quay.io/wvdschel/llama-swap-amdvlk:$(LLAMA_SWAP_VERSION) --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg LLAMA_CPP_VERSION=$(LLAMA_CPP_VERSION) --build-arg LLAMA_CPP_INCLUDE_PRS="$(LLAMA_CPP_INCLUDE_PRS)" .

build-vulkan:
	$(DOCKER_CMD) build --target=llama-swap-vulkan --tag quay.io/wvdschel/llama-swap-vulkan:$(LLAMA_SWAP_VERSION) --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg LLAMA_CPP_VERSION=$(LLAMA_CPP_VERSION) --build-arg LLAMA_CPP_INCLUDE_PRS="$(LLAMA_CPP_INCLUDE_PRS)" .

.PHONY: publish
publish: build
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-amdvlk:$(LLAMA_SWAP_VERSION)
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-vulkan:$(LLAMA_SWAP_VERSION) 

.PHONY: publish-latest
publish-latest: publish
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap-amdvlk:$(LLAMA_SWAP_VERSION) quay.io/wvdschel/llama-swap-amdvlk:latest
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap-vulkan:$(LLAMA_SWAP_VERSION) quay.io/wvdschel/llama-swap-vulkan:latest
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-amdvlk:latest
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-vulkan:latest
