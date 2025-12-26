# Gaming Session Container - Arch Linux with RDNA4 Support
# Requires Mesa 25.0+ for AMD RX 9070XT (gfx1201) support
#
# Build: docker build -t ghcr.io/cmmmota/gaming-session:latest .
# Push:  docker push ghcr.io/cmmmota/gaming-session:latest

FROM archlinux:base-devel@sha256:0a03ad573989e8df9d62ac9d52600a6fb0778016bf5990716a19063e05ebe3c3

LABEL maintainer="cmmmota"
LABEL description="Headless Wayland gaming environment with Steam and Gamescope for RDNA4"

ENV LANG=en_US.UTF-8

# Configure pacman and install CachyOS repositories via official script
RUN sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf && \
    pacman-key --init && \
    pacman -Sy --noconfirm wget && \
    wget https://mirror.cachyos.org/cachyos-repo.tar.xz && \
    tar xvf cachyos-repo.tar.xz && \
    cd cachyos-repo && \
    yes | ./cachyos-repo.sh --install && \
    cd .. && rm -rf cachyos-repo cachyos-repo.tar.xz && \
    # Ensure multilib is enabled (script might handle it, but being safe)
    echo -e '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf && \
    # Generate locale
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# Update system and install base dependencies
# - Base utilities: git wget curl sudo bash
# - Wayland and Sway compositor
# - Graphics stack - Mesa with Vulkan
# - Audio (PipeWire for modern audio support)
# - Gaming utilities: gamescope mangohud gamemode
# - Steam (requires multilib)
# - Fonts for Steam/games
# - Runtime libraries
# - kubectl for debugging
RUN pacman -Syu --noconfirm && \
    yes | pacman -S --noconfirm --needed \
    git wget curl sudo bash \
    sway swaybg wayland wayland-protocols xorg-xwayland \
    foot wofi pciutils \
    cachyos-v3/mesa-git vulkan-radeon libva-mesa-driver libvdpau \
    vulkan-tools vulkan-validation-layers \
    pipewire pipewire-pulse wireplumber \
    gamescope mangohud gamemode lib32-gamemode \
    steam \
    cachyos-v3/lib32-mesa-git lib32-vulkan-radeon lib32-libva-mesa-driver \
    lib32-libnm lib32-nss lib32-libxcrypt-compat lib32-libcurl-gnutls \
    lib32-libpulse lib32-alsa-plugins \
    lib32-glib2 lib32-dbus lib32-libxtst \
    ttf-liberation ttf-dejavu noto-fonts \
    libxkbcommon libinput dbus \
    kubectl && \
    pacman -Scc --noconfirm

# Create gamer user for running Steam (Steam doesn't like running as root)
RUN useradd -m -G audio,video,input,render -s /bin/bash gamer && \
    echo 'gamer ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Generate D-Bus machine-id (required by Steam runtime)
RUN dbus-uuidgen > /etc/machine-id

# Create XDG runtime directory structure
RUN mkdir -p /xdg && \
    chown gamer:gamer /xdg && \
    chmod 0700 /xdg

# Create directories for Steam
RUN mkdir -p /home/gamer/.local/share/Steam && \
    mkdir -p /home/gamer/.steam && \
    mkdir -p /home/gamer/.cache && \
    chown -R gamer:gamer /home/gamer

# Sway configuration for headless operation
COPY sway-config /home/gamer/.config/sway/config
RUN chown -R gamer:gamer /home/gamer/.config

# Entrypoint and Session scripts
COPY entrypoint.sh /entrypoint.sh
COPY session.sh /session.sh
COPY steam-wrapper.sh /home/gamer/steam-wrapper.sh
COPY minimal-dbus-system.conf /etc/dbus-1/minimal-system.conf
RUN chmod +x /entrypoint.sh /session.sh /home/gamer/steam-wrapper.sh && \
    chown gamer:gamer /home/gamer/steam-wrapper.sh

USER gamer
WORKDIR /home/gamer

# Environment for Wayland headless
ENV WLR_BACKENDS=headless
ENV WLR_RENDERER_ALLOW_SOFTWARE=1
ENV XDG_RUNTIME_DIR=/xdg
ENV XDG_SESSION_TYPE=wayland
ENV WAYLAND_DISPLAY=wayland-0
ENV DISPLAY=:0

# AMD GPU environment
ENV AMD_VULKAN_ICD=RADV
ENV RADV_PERFTEST=gpl
ENV MESA_LOADER_DRIVER_OVERRIDE=radeonsi
ENV LIBVA_DRIVER_NAME=radeonsi

# Steam environment
ENV STEAM_DISABLE_HW_SURVEY=1

# Streaming defaults
ENV STREAM_WIDTH=1920
ENV STREAM_HEIGHT=1080
ENV STREAM_REFRESH=60
ENV STREAM_HDR=false

ENTRYPOINT ["/entrypoint.sh"]

