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

ROCM_ARCHES ?= gfx1151 gfx120X gfx110X
ROCM_BUILD ?= b1078

build: build-amdvlk build-vulkan build-rocm

.PHONY: build-amdvlk
build-amdvlk:
	$(DOCKER_CMD) build --target=llama-swap-amdvlk --tag quay.io/wvdschel/llama-swap-amdvlk:$(LLAMA_SWAP_VERSION) --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg LLAMA_CPP_VERSION=$(LLAMA_CPP_VERSION) --build-arg LLAMA_CPP_INCLUDE_PRS="$(LLAMA_CPP_INCLUDE_PRS)" .
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap-amdvlk:$(LLAMA_SWAP_VERSION) quay.io/wvdschel/llama-swap-amdvlk:latest

.PHONY: build-vulkan
build-vulkan:
	$(DOCKER_CMD) build --target=llama-swap-vulkan --tag quay.io/wvdschel/llama-swap-vulkan:$(LLAMA_SWAP_VERSION) --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg LLAMA_CPP_VERSION=$(LLAMA_CPP_VERSION) --build-arg LLAMA_CPP_INCLUDE_PRS="$(LLAMA_CPP_INCLUDE_PRS)" .
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap-vulkan:$(LLAMA_SWAP_VERSION) quay.io/wvdschel/llama-swap-vulkan:latest

.PHONY: build-rocm
build-rocm: $(patsubst %,build-rocm-%,$(ROCM_ARCHES))

build-rocm-%:
	$(DOCKER_CMD) build --target=llama-swap-rocm --tag quay.io/wvdschel/llama-swap-rocm-$(shell echo $* | tr A-Z a-z):$(LLAMA_SWAP_VERSION)-$(ROCM_BUILD) --build-arg LLAMA_SWAP_VERSION=$(LLAMA_SWAP_VERSION) --build-arg ROCM_BUILD=$(ROCM_BUILD) --build-arg ROCM_ARCH="$*" .
	$(DOCKER_CMD) tag quay.io/wvdschel/llama-swap-rocm-$(shell echo $* | tr A-Z a-z):$(LLAMA_SWAP_VERSION)-$(ROCM_BUILD) quay.io/wvdschel/llama-swap-rocm-$(shell echo $* | tr A-Z a-z):latest

.PHONY: publish
publish: build
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-amdvlk:$(LLAMA_SWAP_VERSION)
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-vulkan:$(LLAMA_SWAP_VERSION) 
	for arch in $(shell echo $(ROCM_ARCHES) | tr A-Z a-z); do \
		$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-rocm-$$arch:$(LLAMA_SWAP_VERSION)-$(ROCM_BUILD); \
	done

.PHONY: publish-latest
publish-latest: publish
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-amdvlk:latest
	$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-vulkan:latest
	for arch in $(shell echo $(ROCM_ARCHES) | tr A-Z a-z); do \
		$(DOCKER_CMD) push quay.io/wvdschel/llama-swap-rocm-$$arch:latest; \
	done
