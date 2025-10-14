FROM ubuntu:24.04 AS base
RUN apt-get update
RUN apt-get install -yy vulkan-tools libcurlpp0t64 wget

FROM base AS builder
WORKDIR /build
RUN cd /build
RUN apt-get install -yy libvulkan-dev glslc glslang-tools glslang-dev python3-dev build-essential cmake git-lfs libcurlpp-dev git wget golang npm llvm clang
ARG LLAMA_SWAP_VERSION
RUN git clone -b $LLAMA_SWAP_VERSION --single-branch https://github.com/mostlygeek/llama-swap
RUN make -C /build/llama-swap clean linux

FROM builder AS builder-llama-cpp
ARG LLAMA_CPP_VERSION
ARG LLAMA_CPP_INCLUDE_PRS
RUN git clone https://github.com/ggml-org/llama.cpp
ADD apply_prs.sh /build/apply_prs.sh
RUN /build/apply_prs.sh ${LLAMA_CPP_INCLUDE_PRS}
RUN cd /build/llama.cpp && cmake -B build -DCMAKE_INSTALL_PREFIX=/opt/llama.cpp -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DGGML_STATIC=ON -DGGML_VULKAN=ON -DGGML_RPC=ON
RUN cd /build/llama.cpp && cmake --build build/ -j$(nproc)

FROM base AS llama-swap-vulkan
ENV XDG_CACHE_HOME=/cache
RUN mkdir -p /cache/mesa_shader_cache /cache/mesa_shader_cache_db /cache/radv_builtin_shaders
RUN chmod -R a+rw /cache
RUN mkdir /app
COPY --from=builder /build/llama-swap/build/llama-swap-linux-amd64 /app/llama-swap
COPY --from=builder-llama-cpp /build/llama.cpp/build/bin/llama-server /app/llama-server
ADD ./gpt-oss-cline.gbnf /app/gpt-oss-cline.gbnf
ADD ./glm-4.5-toolcalling.jinja /app/glm-4.5-toolcalling.jinja
HEALTHCHECK CMD curl -f http://localhost:8080/ || exit 1
ENTRYPOINT [ "/app/llama-swap", "-config", "/app/config.yaml" ]

FROM llama-swap-vulkan AS llama-swap-amdvlk
RUN wget https://github.com/GPUOpen-Drivers/AMDVLK/releases/download/v-2025.Q2.1/amdvlk_2025.Q2.1_amd64.deb && dpkg -i amdvlk_2025.Q2.1_amd64.deb

FROM base AS llama-swap-rocm
RUN apt-get install -yy unzip libatomic1
RUN mkdir /app
COPY --from=builder /build/llama-swap/build/llama-swap-linux-amd64 /app/llama-swap
ADD ./gpt-oss-cline.gbnf /app/gpt-oss-cline.gbnf
ADD ./glm-4.5-toolcalling.jinja /app/glm-4.5-toolcalling.jinja
ARG ROCM_ARCH
ARG ROCM_BUILD
ADD https://github.com/lemonade-sdk/llamacpp-rocm/releases/download/${ROCM_BUILD}/llama-${ROCM_BUILD}-ubuntu-rocm-${ROCM_ARCH}-x64.zip /app/llama-${ROCM_BUILD}-ubuntu-rocm-${ROCM_ARCH}-x64.zip
RUN cd /app && unzip llama-${ROCM_BUILD}-ubuntu-rocm-${ROCM_ARCH}-x64.zip && rm llama-${ROCM_BUILD}-ubuntu-rocm-${ROCM_ARCH}-x64.zip
RUN chmod a+x /app/llama-server
ENV LD_LIBRARY_PATH=/app
HEALTHCHECK CMD curl -f http://localhost:8080/ || exit 1
ENTRYPOINT [ "/app/llama-swap", "-config", "/app/config.yaml" ]