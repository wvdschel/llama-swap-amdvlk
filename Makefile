LLAMA_SWAP_VERSION=v158
LLAMA_CPP_VERSION=master

DOCKER_CMD ?= podman

.PHONY: build
build:
	$(DOCKER_CMD) build --tag quay.io/wvdschel/llama-swap-amdvlk:$(LLAMA_SWAP_VERSION) --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg LLAMA_CPP_VERSION=$(LLAMA_CPP_VERSION) .

.PHONY: publish
publish: build
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-amdvlk:$(LLAMA_SWAP_VERSION)

.PHONY: publish-latest
publish-latest: publish
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap-amdvlk:$(LLAMA_SWAP_VERSION) quay.io/wvdschel/llama-swap-amdvlk:latest
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-amdvlk:latest