# Use Arch Linux as base
FROM archlinux/archlinux:base@sha256:559d3926461d1d3cf1b3700782d42945eb90f0be4aa762562ba383415f9ad0f5

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
            git \
            fakeroot \
            base-devel \
            debugedit \
    && \
    echo "**** Section cleanup ****" \
	    && pacman -Scc --noconfirm \
        && rm -fr /var/lib/pacman/sync/* \
        && rm -fr /var/cache/pacman/pkg/* \
    && \
    echo

# Install yay
RUN \
    echo "**** Install Yay ****" \
	    && pacman -Sy \
	    && su - steamshine -c 'git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg --noconfirm --syncdeps --install' \
    && \
    echo "**** Section cleanup ****" \
	    && pacman -Scc --noconfirm \
        && rm -fr /home/default/.cache/yay \
        && rm -fr /var/lib/pacman/sync/* \
        && rm -fr /var/cache/pacman/pkg/* \
        && rm -rf /tmp/yay* \
    && \
    echo

# Install Wayland requirements
ENV \
    WAYLAND_DISPLAY="wayland-0"
RUN \
    echo "**** Install Wayland requirements ****" \
        && su - steamshine -c "yay -Syu --noconfirm --needed wayfire wf-config" \
        && pacman -Syu --noconfirm --needed \
            wayland \
            wayland-protocols \
            xorg-xwayland \
            gamescope \
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
    && \
    echo "**** Section cleanup ****" \
        && pacman -Scc --noconfirm \
        && rm -fr /var/lib/pacman/sync/* \
        && rm -fr /var/cache/pacman/pkg/* \
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

# Copy Wayfire configuration
COPY wayfire.ini /home/steamshine/.config/wayfire.ini
RUN chown steamshine:steamshine /home/steamshine/.config/wayfire.ini && \
    chmod 644 /home/steamshine/.config/wayfire.ini

# Set up volumes
VOLUME ["/home/steamshine/.steam", "/home/steamshine/.local/share/sunshine"]

# Switch to non-root user
USER steamshine
WORKDIR /home/steamshine

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/start.sh"] 