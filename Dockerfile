FROM lizardbyte/sunshine:v2025.525.33445-debian-bookworm@sha256:f3dee81cb24b69059aa01359f337728dd378530e6388158b53270fd0953be92c

USER root

# Add i386 architecture & update
RUN dpkg --add-architecture i386

# Install required dependencies incl. Xorg dummy driver
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    ca-certificates \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# NVIDIA Container Toolkit installation
RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
  apt-get update && \
  apt-get install -y nvidia-container-toolkit

# Add non-free and contrib for Steam + required libs
RUN echo "deb http://deb.debian.org/debian bookworm non-free contrib" >> /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    mesa-vulkan-drivers \
    libglx-mesa0:i386 \
    mesa-vulkan-drivers:i386 \
    libgl1-mesa-dri:i386 \
    libgbm1 \
    libwayland-server0 \
    libwayland-client0 \
    libwayland-cursor0 \
    libwayland-egl1 \
    libx11-6 \
    libx11-6:i386 \
    libxcb1 \
    libxcb1:i386 \
    libxcb-randr0 \
    libxcb-randr0:i386 \
    libxcb-xfixes0 \
    libxcb-xfixes0:i386 \
    libxcb-shape0 \
    libxcb-shape0:i386 \
    libxcb-render0 \
    libxcb-render0:i386 \
    libxcb-xinerama0 \
    libxcb-xinerama0:i386 \
    weston \
    xwayland \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create necessary directories with proper permissions
RUN mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix && \
    mkdir -p /tmp/xdg-runtime && \
    chmod 700 /tmp/xdg-runtime && \
    mkdir -p /home/lizard/.config

# Display configuration
ENV DISPLAY_WIDTH=1920
ENV DISPLAY_HEIGHT=1080
ENV DISPLAY_REFRESH_RATE=60
    
# Create Weston configuration
RUN cat > /home/lizard/.config/weston.ini <<EOF
[core]
backend=headless-backend.so
xwayland=true

[output]
name=headless
mode=${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}@${DISPLAY_REFRESH_RATE}

[xwayland]
command=/usr/bin/Xwayland
EOF

# Steam install
RUN curl -fsSL https://repo.steampowered.com/steam/archive/precise/steam_latest.deb -o steam.deb && \
    dpkg -i steam.deb || true && \
    apt-get update && \
    apt-get install -f -y && \
    rm steam.deb

# NVIDIA runtime config
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV STEAM_RUNTIME=0

# Wayland and X11 environment
ENV XDG_RUNTIME_DIR=/tmp/xdg-runtime
ENV XAUTHORITY=/tmp/.Xauthority
ENV WAYLAND_DISPLAY=wayland-0
ENV DISPLAY=:0

# Copy the updated start.sh which launches Xorg + Sunshine
COPY start.sh /start.sh
RUN chmod 755 /start.sh

# Switch to non-root user
USER lizard

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=3 \
    CMD pgrep -f "sunshine" || exit 1

ENTRYPOINT ["/start.sh"]
