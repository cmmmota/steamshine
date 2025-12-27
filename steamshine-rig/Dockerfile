# Steamshine Rig - Monolithic Gaming Container
# Merges Steam, Sway, and Sunshine into a single image for headless streaming.
#
# Build: docker build -t ghcr.io/cmmmota/steamshine-rig:latest .

FROM archlinux:base-devel@sha256:0a03ad573989e8df9d62ac9d52600a6fb0778016bf5990716a19063e05ebe3c3

LABEL maintainer="cmmmota"
LABEL description="Unified Steam + Sway + Sunshine container for Kubernetes"

# 1. Setup Pacman & CachyOS
RUN sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf && \
    pacman-key --init && \
    pacman -Sy --noconfirm wget && \
    # LizardByte (Sunshine)
    echo -e '\n[lizardbyte]\nSigLevel = Optional\nServer = https://github.com/LizardByte/pacman-repo/releases/latest/download' >> /etc/pacman.conf && \
    # CachyOS (Mesa/Kernel optimized)
    wget https://mirror.cachyos.org/cachyos-repo.tar.xz && \
    tar xvf cachyos-repo.tar.xz && \
    cd cachyos-repo && yes | ./cachyos-repo.sh --install && cd .. && rm -rf cachyos-repo* && \
    # Enable Multilib
    echo -e '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf

# 2. Install Packages
# - Graphics: CachyOS optimized mesa-git
# - Compositor: Hyprland
# - Gaming: steam, mangohud, gamemode
# - Streaming: sunshine
# - UI: hyprpaper, waybar, ttf-font-awesome
# - Utils: sudo, dbus, pipewire, fonts, evdev
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
    base-devel \
    cachyos-v3/mesa-git vulkan-radeon libva-mesa-driver libvdpau \
    hyprland foot \
    hyprpaper waybar ttf-font-awesome \
    mangohud gamemode lib32-gamemode \
    sunshine \
    libinput libinput-tools libevdev evtest \
    seatd \
    pipewire pipewire-pulse wireplumber \
    ttf-dejavu ttf-liberation \
    xorg-xwayland \
    sudo \
    steam \
    cachyos-v3/lib32-mesa-git lib32-vulkan-radeon lib32-libva-mesa-driver \
    lib32-libnm lib32-nss lib32-libxcrypt-compat lib32-libcurl-gnutls \
    lib32-libpulse lib32-alsa-plugins \
    lib32-glib2 lib32-dbus lib32-libxtst \
    lib32-libx11 lib32-libxext lib32-libxrender lib32-libxinerama lib32-libxi \
    python python-pip python-evdev \
    && pacman -Scc --noconfirm
# Install dumb-udev (replaces udevd in container for device discovery)
RUN pip install --break-system-packages dumb-udev

# 3. User Setup
# Creating 'gamer' user. Sunshine will run as this user too.
RUN useradd -m -G audio,video,input,wheel,seat -s /bin/bash gamer && \
    echo 'gamer ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# 4. Directories & Permissions
RUN mkdir -p /xdg && chown gamer:gamer /xdg && chmod 0700 /xdg && \
    mkdir -p /home/gamer/.config/sunshine && \
    mkdir -p /home/gamer/.config/hypr && \
    mkdir -p /home/gamer/.config/waybar && \
    mkdir -p /home/gamer/.local/state/wireplumber && \
    mkdir -p /home/gamer/.local/share/Steam && \
    mkdir -p /home/gamer/.steam && \
    mkdir -p /usr/share/backgrounds && \
    chown -R gamer:gamer /home/gamer

# 5. Configuration Files
COPY sunshine.conf /home/gamer/.config/sunshine/sunshine.conf
COPY hyprland-config /home/gamer/.config/hypr/hyprland.conf
COPY hyprpaper.conf /home/gamer/.config/hypr/hyprpaper.conf
COPY waybar-config /home/gamer/.config/waybar/config
COPY waybar-style.css /home/gamer/.config/waybar/style.css
COPY steamshine_refined.png /usr/share/backgrounds/steamshine_refined.png
COPY steam_icon_themed.png /usr/share/backgrounds/steam_icon_themed.png
COPY controller-listener.py /usr/local/bin/controller-listener.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chmod +x /usr/local/bin/controller-listener.py && \
    chown gamer:gamer /home/gamer/.config/sunshine/sunshine.conf && \
    chown gamer:gamer /home/gamer/.config/hypr/hyprland.conf && \
    chown gamer:gamer /home/gamer/.config/hypr/hyprpaper.conf && \
    chown -R gamer:gamer /home/gamer/.config/waybar && \
    chown gamer:gamer /usr/share/backgrounds/steamshine_refined.png && \
    chown gamer:gamer /usr/share/backgrounds/steam_icon_themed.png

# 6. Grant file capabilities for non-root operation
# - sunshine: CAP_SYS_ADMIN for uinput device creation
# - pipewire: CAP_SYS_NICE for realtime audio priority
# - gamemoded: CAP_SYS_NICE for game realtime priority (replaces Gamescope's role)
RUN setcap cap_sys_admin+ep $(readlink -f $(which sunshine)) && \
    setcap cap_sys_nice+ep $(readlink -f $(which pipewire)) && \
    setcap cap_sys_nice+ep $(readlink -f $(which gamemoded))

# 7. Generate machine-id for D-Bus (required by WirePlumber)
RUN dbus-uuidgen > /etc/machine-id

USER gamer
WORKDIR /home/gamer

# Environment
ENV XDG_RUNTIME_DIR=/xdg
ENV WAYLAND_DISPLAY=wayland-0
ENV XDG_SESSION_TYPE=wayland
ENV WLR_NO_HARDWARE_CURSORS=1
ENV WLR_BACKENDS=drm

# AMD Optimizations
ENV AMD_VULKAN_ICD=RADV
ENV RADV_PERFTEST=gpl
ENV MESA_LOADER_DRIVER_OVERRIDE=radeonsi
ENV LIBVA_DRIVER_NAME=radeonsi

# Resolution Defaults
ENV STREAM_WIDTH=1920
ENV STREAM_HEIGHT=1080
ENV STREAM_REFRESH=60

ENTRYPOINT ["/entrypoint.sh"]
