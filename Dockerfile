# Use Ubuntu 24.04 LTS as base (Best for NVIDIA Container Toolkit compatibility)
FROM ubuntu:24.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables
ENV DISPLAY_WIDTH=1920
ENV DISPLAY_HEIGHT=1080
ENV DISPLAY_REFRESH=60
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV NVIDIA_VISIBLE_DEVICES=all

# 1. Install Base Dependencies + Graphics Stack
#    We install explicit NVIDIA libs here to ensure the container has the userspace shims
#    even if injection is partial.
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    nano \
    gpg \
    pkg-config \
    software-properties-common \
    libgl1-mesa-dri \
    libnvidia-egl-wayland1 \
    libglx-mesa0 \
    libegl1 \
    libgles2 \
    vulkan-tools \
    mesa-utils \
    mesa-vulkan-drivers \
    libnvidia-egl-wayland1 \
    xwayland \
    dbus-x11 \
    libcap2-bin \
    pulseaudio \
    pipewire \
    pipewire-pulse \
    wireplumber \
    locales \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup Locales
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# 3. Install Sunshine (LizardByte) - Download .deb directly
RUN wget -O sunshine.deb "https://github.com/LizardByte/Sunshine/releases/download/v2025.1210.519/sunshine-ubuntu-24.04-amd64.deb" && \
    apt-get update && apt-get install -y ./sunshine.deb && \
    rm sunshine.deb && \
    rm -rf /var/lib/apt/lists/*

# 4. Install Steam
#    Enable 32-bit architecture for Steam
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
    steam \
    libgl1:i386 \
    libglx-mesa0:i386 \
    libgtk2.0-0:i386 \
    && rm -rf /var/lib/apt/lists/*

# 5. Install Gamescope (Compatible Version for Ubuntu 24.04)
#    Ubuntu 24.04 dropped gamescope from repos.
#    Newer versions (3.16+) require Wayland 1.23, which 24.04 lacks.
#    We use v3.12.5 which is confirmed to work with system libraries.
RUN wget -O gamescope.deb "https://github.com/akdor1154/gamescope-pkg/releases/download/v3.12.5-2/gamescope_3.12.5-2_amd64.deb" && \
    apt-get update && \
    apt-get install -y ./gamescope.deb && \
    rm gamescope.deb && \
    rm -rf /var/lib/apt/lists/*

# 6. Install Seatd (for direct DRM access)
RUN apt-get update && apt-get install -y seatd libseat1 && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user (Groups should exist now after package installs)
RUN useradd -m -G video,audio,input,render steamshine || \
    (groupadd -f render && groupadd -f input && useradd -m -G video,audio,input,render steamshine)

# 7. Setup Directories & Permissions
RUN mkdir -p /home/steamshine/.steam /home/steamshine/.local/share/Steam \
    /home/steamshine/.config/sunshine /home/steamshine/.config/gamescope && \
    chown -R steamshine:steamshine /home/steamshine

# Generate machine-id for dbus
RUN dbus-uuidgen > /etc/machine-id

# Grant capabilities for Gamescope priority/nice
RUN setcap 'cap_sys_nice=eip' $(which gamescope) || true

# Copy startup scripts
COPY start.sh /usr/local/bin/start.sh
COPY sunshine-wrapper.sh /usr/local/bin/sunshine-wrapper.sh
RUN chmod +x /usr/local/bin/start.sh /usr/local/bin/sunshine-wrapper.sh

# Switch to user
USER steamshine
WORKDIR /home/steamshine

# Volumes
VOLUME ["/home/steamshine/.steam", "/home/steamshine/.local/share/sunshine"]

ENTRYPOINT ["/usr/local/bin/start.sh"]
