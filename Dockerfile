# Use Arch Linux as base
FROM archlinux:latest@sha256:69a7520c58d27f1b2ee52dd61f6496e632582616b89c7952865f56b44617772b

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables
ENV DISPLAY_WIDTH=1920
ENV DISPLAY_HEIGHT=1080
ENV DISPLAY_REFRESH=60

# 1. Configure Pacman & Repositories
#    Enable multilib (for Steam/32-bit games) and add LizardByte repo (for Sunshine)
RUN echo "[multilib]" >> /etc/pacman.conf && \
    echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && \
    echo -e "\n[lizardbyte]\nSigLevel = Optional\nServer = https://github.com/LizardByte/pacman-repo/releases/latest/download" >> /etc/pacman.conf

# 2. Install Dependencies
#    - Core: base-devel, git, sudo
#    - Graphics (AMD): mesa, vulkan-radeon, libva-mesa-driver (plus lib32 variants)
#    - Audio: pipewire, wireplumber, pipewire-pulse, pipewire-alsa
#    - Gaming/Streaming: steam, sunshine, gamescope
#    - Utilities: xorg-xwayland, dbus
RUN pacman -Sy --noconfirm && \
    pacman -S --noconfirm \
    base-devel \
    git \
    sudo \
    nano \
    wget \
    # Graphics (AMD)
    mesa \
    lib32-mesa \
    vulkan-radeon \
    lib32-vulkan-radeon \
    libva-mesa-driver \
    lib32-libva-mesa-driver \
    vulkan-tools \
    # Audio
    pipewire \
    lib32-pipewire \
    wireplumber \
    pipewire-pulse \
    pipewire-alsa \
    # Gaming & Streaming
    steam \
    gamescope \
    sunshine \
    # Utilities
    xorg-xwayland \
    dbus \
    ttf-dejavu \
    wqy-zenhei \
    mesa-utils \
    lib32-mesa-utils \
    libva-utils \
    wayland-utils \
    && pacman -Scc --noconfirm

# 3. Setup User
# Note: 'render' group is crucial for DRI access on many systems (including Arch)
RUN groupadd -r render 2>/dev/null || true && \
    useradd -m -G video,audio,input,storage,wheel,render steamshine && \
    chmod 660 /dev/uinput 2>/dev/null || true && \
    echo "steamshine ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 4. Setup Directories & Permissions
RUN mkdir -p /home/steamshine/.steam /home/steamshine/.local/share/Steam \
    /home/steamshine/.config/sunshine /home/steamshine/.config/gamescope && \
    chown -R steamshine:steamshine /home/steamshine

# 5. Capabilities for Gamescope (priority/nice)
RUN setcap 'cap_sys_nice=eip' $(which gamescope) || true

# 6. Copy Scripts
COPY start.sh /usr/local/bin/start.sh
COPY sunshine-wrapper.sh /usr/local/bin/sunshine-wrapper.sh
RUN chmod +x /usr/local/bin/start.sh /usr/local/bin/sunshine-wrapper.sh

# 7. Final Config
USER steamshine
WORKDIR /home/steamshine

# Volumes
VOLUME ["/home/steamshine/.steam", "/home/steamshine/.config/sunshine"]

ENTRYPOINT ["/usr/local/bin/start.sh"]
