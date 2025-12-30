FROM ubuntu:25.10 AS base
RUN apt-get update
RUN apt-get install -yy vulkan-tools libcurlpp0t64 wget

FROM ubuntu:24.04 AS base-lts
RUN apt-get update
RUN apt-get install -yy vulkan-tools libcurlpp0t64 wget

FROM base AS builder
WORKDIR /build
RUN cd /build
RUN apt-get install -yy libvulkan-dev glslc glslang-tools glslang-dev python3-dev build-essential cmake git-lfs libcurlpp-dev git wget golang npm llvm clang
ARG LLAMA_SWAP_VERSION
RUN git clone -b $LLAMA_SWAP_VERSION --single-branch https://github.com/mostlygeek/llama-swap
RUN make -C /build/llama-swap clean linux

FROM builder AS builder-vulkan
ARG LLAMA_CPP_VERSION
ARG LLAMA_CPP_INCLUDE_PRS
RUN git clone https://github.com/ggml-org/llama.cpp
ADD apply_prs.sh /build/apply_prs.sh
RUN /build/apply_prs.sh ${LLAMA_CPP_INCLUDE_PRS}
RUN cd /build/llama.cpp && cmake -B build -DCMAKE_INSTALL_PREFIX=/opt/llama.cpp -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DGGML_STATIC=ON -DGGML_VULKAN=ON -DGGML_RPC=ON
RUN cd /build/llama.cpp && nice cmake --build build/ -j$(nproc)

FROM base AS llama-swap-vulkan
RUN apt-get clean
RUN apt-get install software-properties-common -yy
RUN add-apt-repository ppa:kisak/kisak-mesa -yy
RUN apt update -yy && apt upgrade -yy
RUN mkdir -p /cache/mesa_shader_cache /cache/mesa_shader_cache_db /cache/radv_builtin_shaders
RUN chmod -R a+rw /cache
RUN mkdir /app
COPY --from=builder        /build/llama-swap/build/llama-swap-linux-amd64 /app/llama-swap
COPY --from=builder-vulkan /build/llama.cpp/build/bin/llama-server /app/llama-server

FROM llama-swap-vulkan AS llama-swap-amdvlk
RUN wget https://github.com/GPUOpen-Drivers/AMDVLK/releases/download/v-2025.Q2.1/amdvlk_2025.Q2.1_amd64.deb && dpkg -i amdvlk_2025.Q2.1_amd64.deb

FROM base-lts AS builder-rocm
WORKDIR /build
RUN cd /build
RUN apt-get install -yy python3-dev build-essential cmake git-lfs libcurlpp-dev git wget golang npm llvm clang
ARG LLAMA_CPP_VERSION
ARG LLAMA_CPP_INCLUDE_PRS
RUN git clone https://github.com/ggml-org/llama.cpp
ADD apply_prs.sh /build/apply_prs.sh
RUN /build/apply_prs.sh ${LLAMA_CPP_INCLUDE_PRS}
ARG ROCM_ARCH

ARG LLAMA_SWAP_VERSION
RUN git clone -b $LLAMA_SWAP_VERSION --single-branch https://github.com/mostlygeek/llama-swap
RUN make -C /build/llama-swap clean linux
RUN wget https://repo.radeon.com/amdgpu-install/7.1/ubuntu/noble/amdgpu-install_7.1.70100-1_all.deb -O /amdgpu-install.deb
RUN apt-get install -yy /amdgpu-install.deb && apt-get update
RUN apt-get install -yy python3-setuptools python3-wheel rocm rocm-hip-sdk rocm-dev rocwmma-dev
RUN cd /build/llama.cpp && cmake -B build-rocm -DCMAKE_INSTALL_PREFIX=/opt/llama.cpp -DCMAKE_BUILD_TYPE=Release -DGGML_HIP=ON -DGPU_TARGETS=${ROCM_ARCH} -DGGML_RPC=ON -DGGML_HIP_ROCWMMA_FATTN=ON
RUN cd /build/llama.cpp && nice cmake --build build-rocm/ -j$(nproc)

FROM base-lts AS builder-zluda
WORKDIR /build
RUN cd /build
RUN apt-get install -yy python3-dev build-essential cmake git-lfs libcurlpp-dev git wget golang npm llvm clang
ARG LLAMA_CPP_VERSION
ARG LLAMA_CPP_INCLUDE_PRS
RUN git clone https://github.com/ggml-org/llama.cpp
ADD apply_prs.sh /build/apply_prs.sh
RUN /build/apply_prs.sh ${LLAMA_CPP_INCLUDE_PRS}
ARG ROCM_ARCH

ARG LLAMA_SWAP_VERSION
RUN git clone -b $LLAMA_SWAP_VERSION --single-branch https://github.com/mostlygeek/llama-swap
RUN make -C /build/llama-swap clean linux
RUN wget https://repo.radeon.com/amdgpu-install/6.4.3/ubuntu/noble/amdgpu-install_6.4.60403-1_all.deb -O /amdgpu-install.deb
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb -O cuda-keyring.deb
RUN apt-get install -yy /amdgpu-install.deb ./cuda-keyring.deb && apt-get update
RUN apt-get install -yy python3-setuptools python3-wheel rocm rocm-hip-sdk rocm-dev rocwmma-dev cuda-toolkit
RUN realpath /usr/local/cuda-13.1/targets/x86_64-linux/lib/stubs/libcuda.so
RUN ln -s /usr/local/cuda-13.1/targets/x86_64-linux/lib/stubs/libcuda.so /usr/local/cuda-13.1/targets/x86_64-linux/lib/stubs/libcuda.so.1
RUN cd /build/llama.cpp && cmake -B build-zluda -DCMAKE_INSTALL_PREFIX=/opt/llama.cpp -DCMAKE_BUILD_TYPE=Release -DGGML_CUDA=ON -DGGML_RPC=ON -DCMAKE_CUDA_ARCHITECTURES="75;86;89" -DGGML_CUDA_FORCE_CUBLAS=1 -DCMAKE_CUDA_COMPILER=/usr/local/cuda-13.1/bin/nvcc -DCMAKE_INSTALL_RPATH="/usr/local/cuda-13.1/lib;\$ORIGIN" -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
RUN cd /build/llama.cpp && nice cmake --build build-zluda/ -j$(nproc)

FROM base-lts AS llama-swap-rocm
RUN mkdir -p /cache/mesa_shader_cache /cache/mesa_shader_cache_db /cache/radv_builtin_shaders
RUN chmod -R a+rw /cache
RUN mkdir /app
COPY --from=builder /build/llama-swap/build/llama-swap-linux-amd64 /app/llama-swap
COPY --from=builder-rocm /build/llama.cpp/build-rocm/bin/llama-server /app/llama-server
COPY --from=builder-rocm /build/llama.cpp/build-rocm/bin/*.so* /app/
COPY --from=builder-rocm /opt/rocm*/lib/*.so* /app/
COPY --from=builder-rocm /usr/lib/x86_64-linux-gnu/libgomp* /app/
COPY --from=builder-rocm /usr/lib/x86_64-linux-gnu/libnuma* /app/
ADD ./remove-unnecessary-libs.sh /app/remove-unnecessary-libs.sh
ENV LD_LIBRARY_PATH=/app
RUN /app/remove-unnecessary-libs.sh

FROM base-lts AS llama-swap-zluda
RUN mkdir -p /cache/mesa_shader_cache /cache/mesa_shader_cache_db /cache/radv_builtin_shaders
RUN chmod -R a+rw /cache
RUN mkdir /app

COPY --from=builder-zluda /usr/local/cuda-*/targets/x86_64-linux/lib/* /opt/cuda
RUN wget https://github.com/vosen/ZLUDA/releases/download/v6-preview.38/zluda-linux-629158c.tar.gz -O zluda.tar.gz
RUN tar xf ./zluda.tar.gz -C /opt/ && rm zluda.tar.gz

COPY --from=builder /build/llama-swap/build/llama-swap-linux-amd64 /app/llama-swap
COPY --from=builder-zluda /build/llama.cpp/build-zluda/bin/llama-server /app/llama-server
COPY --from=builder-zluda /build/llama.cpp/build-zluda/bin/*.so* /app/
COPY --from=builder-zluda /opt/rocm*/lib/*.so* /app/
COPY --from=builder-zluda /usr/lib/x86_64-linux-gnu/libgomp* /app/
COPY --from=builder-zluda /usr/lib/x86_64-linux-gnu/libnuma* /app/

ADD ./remove-unnecessary-libs.sh /app/remove-unnecessary-libs.sh
ENV LD_LIBRARY_PATH=/app:/opt/zluda:/opt/cuda
RUN /app/remove-unnecessary-libs.sh

RUN ldd /app/llama-server

FROM scratch AS llama-swap-vulkan-final
COPY --from=llama-swap-vulkan / /
ENV XDG_CACHE_HOME=/cache
ENV LD_LIBRARY_PATH=/app
ENTRYPOINT [ "/app/llama-swap", "-config", "/app/config.yaml" ]

FROM scratch AS llama-swap-amdvlk-final
COPY --from=llama-swap-amdvlk / /
ENV XDG_CACHE_HOME=/cache
ENV LD_LIBRARY_PATH=/app
ENTRYPOINT [ "/app/llama-swap", "-config", "/app/config.yaml" ]

FROM scratch AS llama-swap-rocm-final
COPY --from=llama-swap-rocm / /
ENV LD_LIBRARY_PATH=/app
ENV XDG_CACHE_HOME=/cache
ENTRYPOINT [ "/app/llama-swap", "-config", "/app/config.yaml" ]

FROM scratch AS llama-swap-zluda-final
COPY --from=llama-swap-zluda / /
ENV LD_LIBRARY_PATH=/app:/opt/zluda:/opt/cuda
ENV XDG_CACHE_HOME=/cache
ENTRYPOINT [ "/app/llama-swap", "-config", "/app/config.yaml" ]

FROM llama-swap-rocm-final AS llama-swap-rocm-igpu-final
ENV GGML_CUDA_ENABLE_UNIFIED_MEMORY=1
