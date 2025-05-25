FROM debian:bookworm-slim@sha256:90522eeb7e5923ee2b871c639059537b30521272f10ca86fdbbbb2b75a8c40cd

ENV DEBIAN_FRONTEND=noninteractive

# Display configuration
ENV DISPLAY_WIDTH=1920
ENV DISPLAY_HEIGHT=1080
ENV DISPLAY_REFRESH_RATE=60

# Sunshine version
ARG SUNSHINE_VERSION=v2025.122.141614
LABEL org.opencontainers.image.version.sunshine=${SUNSHINE_VERSION}

# Step 1: Enable i386 architecture and update
RUN dpkg --add-architecture i386 && apt-get update

# Step 2: Install core system utilities and runtime dependencies
RUN apt-get install -y --no-install-recommends \
    curl wget unzip pulseaudio \
    xz-utils zenity python3-apt libgtk2.0-0 libcurl4 \
    libudev1 libjsoncpp25 libnm0 libnotify4 \
    libgl1-mesa-dri:i386 libgl1-mesa-glx:i386 libsdl2-2.0-0:i386 \
    mesa-vulkan-drivers vulkan-tools \
    libnss3 libxss1 libgconf-2-4 libasound2 \
    gdebi-core ca-certificates policykit-1 xterm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Step 3: Install Steam from official .deb
RUN wget https://steamcdn-a.akamaihd.net/client/installer/steam.deb && \
    gdebi -n steam.deb && rm steam.deb

# Step 4: Install gamescope from Debian package
RUN apt-get update && apt-get install -y --no-install-recommends \
    gamescope \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && setcap 'CAP_SYS_NICE=eip' /usr/games/gamescope

# Step 5: Create user and set permissions
RUN useradd -m -s /bin/bash steamshine && \
    usermod -aG video steamshine

# Step 6: Install Sunshine (latest release from GitHub)
RUN wget https://github.com/LizardByte/Sunshine/releases/download/${SUNSHINE_VERSION}/sunshine-debian-bookworm-amd64.deb && \
    apt-get update && apt-get install -y ./sunshine-debian-bookworm-amd64.deb && \
    rm sunshine-debian-bookworm-amd64.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Step 7: Set working directory and entrypoint script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

USER steamshine
WORKDIR /home/steamshine

ENTRYPOINT ["/usr/local/bin/start.sh"]
