# Use Arch Linux as base
FROM archlinux/archlinux:base@sha256:0a0e9d52dd484e641f5888fff45fbaff2e45f9b05ff2b7e99d7d32b08c2537e3

# Set environment variables
ENV DISPLAY_WIDTH=1920
ENV DISPLAY_HEIGHT=1080
ENV DISPLAY_REFRESH=60


# Create non-root user
RUN useradd -m -G video,audio,users,input steamshine && \
    echo "steamshine ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Update package repos
RUN \
    echo "**** Update package manager ****" \
        && sed -i 's/^NoProgressBar/#NoProgressBar/g' /etc/pacman.conf \
        && echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf \
        && echo -e "\n[lizardbyte]\nSigLevel = Optional\nServer = https://github.com/LizardByte/pacman-repo/releases/latest/download" >> /etc/pacman.conf \
    && \
    echo

# Re-install certificates
RUN \
    echo "**** Install certificates ****" \
	    && pacman -Syu --noconfirm --needed \
            ca-certificates \
    && \
    echo "**** Section cleanup ****" \
	    && pacman -Scc --noconfirm \
        && rm -fr /var/lib/pacman/sync/* \
        && rm -fr /var/cache/pacman/pkg/* \
    && \
    echo

# Install core packages
RUN \
    echo "**** Install tools ****" \
	    && pacman -Syu --noconfirm --needed \
            sudo \
            bash \
            bash-completion \
            curl \
            less \
            nano \
            procps \
            sudo \
            wget \
            which \
            vulkan-icd-loader \
            vulkan-tools \
    && \
    echo "**** Section cleanup ****" \
	    && pacman -Scc --noconfirm \
        && rm -fr /var/lib/pacman/sync/* \
        && rm -fr /var/cache/pacman/pkg/* \
    && \
    echo

# Install Wayland requirements
ENV \
    WAYLAND_DISPLAY="wayland-0"
RUN \
    echo "**** Install Wayland requirements ****" \
        && pacman -Syu --noconfirm --needed \
            wayland \
            wayland-protocols \
            xorg-xwayland \
            waypipe \
            gamescope \
            weston \
        && setcap cap_sys_nice+p $(readlink -f $(which gamescope)) \
    && \
    echo "**** Section cleanup ****" \
        && pacman -Scc --noconfirm \
        && rm -fr /var/lib/pacman/sync/* \
        && rm -fr /var/cache/pacman/pkg/* \
    && \
    echo

# Install Pipewire requirements
ENV \
    PIPEWIRE_SOCKET_DIR="/tmp/pipewire-0" \
    PIPEWIRE_CONFIG_DIR="/etc/pipewire" \
    PIPEWIRE_CONFIG_FILE="/etc/pipewire/pipewire.conf"
RUN \
    echo "**** Install Pipewire requirements ****" \
        && pacman -Syu --noconfirm --needed \
            pipewire \
            pipewire-pulse \
            pipewire-zeroconf \
            pipewire-media-session \
    && \
    echo "**** Section cleanup ****" \
        && pacman -Scc --noconfirm \
        && rm -fr /var/lib/pacman/sync/* \
        && rm -fr /var/cache/pacman/pkg/* \
    && \
    echo

# Set up audio permissions
RUN \
    echo "**** Set up audio permissions ****" \
        && echo "SUBSYSTEM==\"sound\", MODE=\"rwm\"" > /etc/udev/rules.d/99-steamshine-audio.rules \
        && udevadm trigger \
    && \
    echo

# Setup video streaming deps
RUN \
    echo "**** Install video streaming deps ****" \
        && pacman -Syu --noconfirm --needed \
            libva \
            libva-mesa-driver \
            libva-intel-driver \
    && \
    echo "**** Section cleanup ****" \
	    && pacman -Scc --noconfirm \
        && rm -fr /var/lib/pacman/sync/* \
        && rm -fr /var/cache/pacman/pkg/* \
    && \
    echo

# Install tools for monitoring hardware
RUN \
    echo "**** Install tools for monitoring hardware ****" \
        && pacman -Syu --noconfirm --needed \
            #cpu-x \
            htop \
            libva-utils \
            vdpauinfo \
    && \
    echo "**** Section cleanup ****" \
	    && pacman -Scc --noconfirm \
        && rm -fr /var/lib/pacman/sync/* \
        && rm -fr /var/cache/pacman/pkg/* \
    && \
    echo

# Install Steam
RUN \
    echo "**** Install Steam ****" \
	    && pacman -Syu --noconfirm --needed \
            steam-native-runtime \
            
    && \
    echo "**** Section cleanup ****" \
	    && pacman -Scc --noconfirm \
        && rm -fr /var/lib/pacman/sync/* \
        && rm -fr /var/cache/pacman/pkg/* \
    && \
    echo

# Initialize Steam directories with correct permissions
RUN mkdir -p /home/steamshine/.steam /home/steamshine/.local/share/Steam && \
    chown -R steamshine:steamshine /home/steamshine && \
    chmod -R 755 /home/steamshine/.steam /home/steamshine/.local/share/Steam

# Install Sunshine from official repo
RUN \
    echo "**** Install Sunshine ****" \
        && pacman -Syu --noconfirm --needed \
            miniupnpc \
            lizardbyte/sunshine \
        && setcap cap_sys_admin+p $(readlink -f $(which sunshine)) \
        && setcap cap_sys_nice+p $(readlink -f $(which sunshine)) \
    && \
    echo "**** Section cleanup ****" \
	    && pacman -Scc --noconfirm \
        && rm -fr /var/lib/pacman/sync/* \
        && rm -fr /var/cache/pacman/pkg/* \
    && \
    echo

# Initialize Sunshine directories with correct permissions
RUN mkdir -p /home/steamshine/.config/sunshine && \
    chown -R steamshine:steamshine /home/steamshine/.config/sunshine && \
    chmod -R 755 /home/steamshine/.config/sunshine

# Create startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Copy Weston configuration
COPY weston.ini /home/steamshine/.config/weston.ini
RUN chown steamshine:steamshine /home/steamshine/.config/weston.ini && \
    chmod 644 /home/steamshine/.config/weston.ini


# Set up volumes
VOLUME ["/home/steamshine/.steam", "/home/steamshine/.local/share/sunshine"]

# Switch to non-root user
USER steamshine
WORKDIR /home/steamshine

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/start.sh"] 