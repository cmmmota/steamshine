# Sunshine Server Container - Arch Linux with RDNA4 Support
# Streaming server that captures from Gaming Session pod
#
# Build: docker build -t ghcr.io/cmmmota/sunshine-server:latest .
# Push:  docker push ghcr.io/cmmmota/sunshine-server:latest

FROM archlinux:base@sha256:69a7520c58d27f1b2ee52dd61f6496e632582616b89c7952865f56b44617772b

LABEL maintainer="cmmmota"
LABEL description="Sunshine game streaming server with kubectl for session management"

# Configure pacman for parallel downloads, add LizardByte repo, and install CachyOS repos
RUN sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf && \
    echo -e '\n[lizardbyte]\nSigLevel = Optional\nServer = https://github.com/LizardByte/pacman-repo/releases/latest/download' >> /etc/pacman.conf && \
    pacman-key --init && \
    pacman -Sy --noconfirm wget && \
    wget https://mirror.cachyos.org/cachyos-repo.tar.xz && \
    tar xvf cachyos-repo.tar.xz && \
    cd cachyos-repo && \
    yes | ./cachyos-repo.sh --install && \
    cd .. && rm -rf cachyos-repo cachyos-repo.tar.xz

# Update system and install dependencies
# - Wayland client libraries (Sunshine needs to connect to Wayland)
# - Graphics stack - Mesa with Vulkan and VA-API
# - Encoding libraries
# - kubectl for scaling gaming pods
# - Sunshine from official LizardByte repo
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
    wayland wayland-protocols \
    mesa-git vulkan-radeon libva-mesa-driver libvdpau \
    ffmpeg libpulse \
    kubectl \
    sunshine && \
    pacman -Scc --noconfirm

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
