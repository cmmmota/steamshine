# Sunshine Server Container - Arch Linux with RDNA4 Support
# Streaming server that captures from Gaming Session pod
#
# Build: docker build -t ghcr.io/cmmmota/sunshine-server:latest .
# Push:  docker push ghcr.io/cmmmota/sunshine-server:latest

FROM archlinux:base-devel

LABEL maintainer="cmmmota"
LABEL description="Sunshine game streaming server with kubectl for session management"

# Configure pacman for parallel downloads
RUN sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# Update system and install dependencies
# - Base utilities: git wget curl sudo bash
# - Wayland client libraries (Sunshine needs to connect to Wayland)
# - Graphics stack - Mesa with Vulkan and VA-API
# - Encoding libraries: ffmpeg libpulse
# - Build dependencies for Sunshine
# - kubectl for scaling gaming pods
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
    git wget curl sudo bash \
    wayland wayland-protocols \
    mesa vulkan-radeon vulkan-icd-loader libva-mesa-driver libvdpau \
    ffmpeg libpulse \
    cmake ninja gcc clang boost boost-libs \
    openssl avahi libevdev libcap miniupnpc libnotify \
    kubectl && \
    pacman -Scc --noconfirm

# Install Sunshine
# Option 1: From source (recommended for latest features)
RUN git clone --recurse-submodules https://github.com/LizardByte/Sunshine.git /tmp/sunshine && \
    cd /tmp/sunshine && \
    mkdir build && cd build && \
    cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DSUNSHINE_ENABLE_WAYLAND=ON \
        -DSUNSHINE_ENABLE_X11=OFF \
        -DSUNSHINE_ENABLE_DRM=ON \
        -DSUNSHINE_ENABLE_CUDA=OFF \
        .. && \
    ninja && \
    ninja install && \
    rm -rf /tmp/sunshine

# Create sunshine user
RUN useradd -m -G audio,video,input -s /bin/bash sunshine && \
    echo 'sunshine ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Create config directories
RUN mkdir -p /home/sunshine/.config/sunshine && \
    mkdir -p /config && \
    chown -R sunshine:sunshine /home/sunshine /config

# Create XDG runtime directory
RUN mkdir -p /xdg && \
    chown sunshine:sunshine /xdg && \
    chmod 0700 /xdg

# Default Sunshine configuration
COPY sunshine.conf /home/sunshine/.config/sunshine/sunshine.conf
RUN chown sunshine:sunshine /home/sunshine/.config/sunshine/sunshine.conf

# Entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER sunshine
WORKDIR /home/sunshine

# Wayland environment
ENV XDG_RUNTIME_DIR=/xdg
ENV WAYLAND_DISPLAY=wayland-0

# AMD GPU environment
ENV AMD_VULKAN_ICD=RADV
ENV RADV_PERFTEST=gpl
ENV MESA_LOADER_DRIVER_OVERRIDE=radeonsi
ENV LIBVA_DRIVER_NAME=radeonsi

# Sunshine ports
EXPOSE 47984/tcp 47989/tcp 47990/tcp 48010/tcp
EXPOSE 47998/udp 47999/udp 48000/udp 48002/udp 48010/udp

ENTRYPOINT ["/entrypoint.sh"]

