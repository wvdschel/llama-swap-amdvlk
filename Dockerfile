FROM fedora:42 AS base
RUN dnf update -yy
RUN dnf install -yy vulkan-loader curlpp wget

FROM base AS builder

WORKDIR /build
RUN cd /build

RUN dnf install -yy vulkan-devel glslc glslang python-devel @development-tools cmake git-lfs curlpp-devel git wget golang npm clang++

ARG LLAMA_SWAP_VERSION
RUN git clone -b $LLAMA_SWAP_VERSION --single-branch https://github.com/mostlygeek/llama-swap
RUN make -C /build/llama-swap clean linux

ARG LLAMA_CPP_VERSION
ARG LLAMA_CPP_INCLUDE_PRS

RUN git clone https://github.com/ggml-org/llama.cpp
ADD apply_prs.sh /build/apply_prs.sh
RUN /build/apply_prs.sh ${LLAMA_CPP_INCLUDE_PRS}
RUN cd /build/llama.cpp && cmake -B build -DCMAKE_INSTALL_PREFIX=/opt/llama.cpp -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DGGML_STATIC=ON -DGGML_VULKAN=ON -DGGML_RPC=ON
RUN cd /build/llama.cpp && cmake --build build/ -j$(nproc)

FROM base as llama-swap-vulkan

ENV XDG_CACHE_HOME=/cache
RUN mkdir -p /cache/{mesa_shader_cache_db,radv_builtin_shaders}
RUN mkdir /app
COPY --from=builder /build/llama-swap/build/llama-swap-linux-amd64 /app/llama-swap
COPY --from=builder /build/llama.cpp/build/bin/llama-server /app/llama-server
ADD ./gpt-oss-cline.gbnf /app/gpt-oss-cline.gbnf
ADD ./glm-4.5-toolcalling.jinja /app/glm-4.5-toolcalling.jinja

HEALTHCHECK CMD curl -f http://localhost:8080/ || exit 1
ENTRYPOINT [ "/app/llama-swap", "-config", "/app/config.yaml" ]

FROM llama-swap-vulkan as llama-swap-amdvlk
RUN wget https://github.com/GPUOpen-Drivers/AMDVLK/releases/download/v-2025.Q2.1/amdvlk-2025.Q2.1.x86_64.rpm && dnf install -yy ./amdvlk-2025.Q2.1.x86_64.rpm
