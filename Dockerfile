FROM lizardbyte/sunshine:v2025.524.144138-debian-bookworm@sha256:b95de5d12a7cda3d38117562294d9700c5025fb5eda42b63eea1b6ed65187a77

USER root

# Install dependencies and enable 32-bit support
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    ca-certificates \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Add non-free and contrib repositories for Steam
RUN echo "deb http://deb.debian.org/debian bookworm non-free contrib" >> /etc/apt/sources.list

# Install required packages
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
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install Steam
RUN curl -fsSL https://repo.steampowered.com/steam/archive/precise/steam_latest.deb -o steam.deb && \
    dpkg -i steam.deb || true && \
    apt-get update && \
    apt-get install -f -y && \
    rm steam.deb

# NVIDIA runtime configuration
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV STEAM_RUNTIME=0

# Copy and set up startup script
COPY start.sh /start.sh
RUN chmod 755 /start.sh

# Health check with longer initial delay for first-time setup
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=3 \
    CMD pgrep -f "sunshine" || exit 1

ENTRYPOINT ["/start.sh"]