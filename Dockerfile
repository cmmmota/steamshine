# Use Arch Linux as base
FROM archlinux/archlinux:base@sha256:ea70726a696f34f2ec1ff87a16520fce110ee212ea5edeec57762fe167bbc3e9

# Set environment variables
ENV DISPLAY_WIDTH=1920
ENV DISPLAY_HEIGHT=1080
ENV DISPLAY_REFRESH=60


# Create non-root user
RUN useradd -m -G video,audio,input steamshine

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
    # echo "**** Section cleanup ****" \
	#     && pacman -Scc --noconfirm \
    #     && rm -fr /var/lib/pacman/sync/* \
    #     && rm -fr /var/cache/pacman/pkg/* \
    # && \
    echo

# Install core packages
RUN \
    echo "**** Install tools ****" \
	    && pacman -Syu --noconfirm --needed \
            dbus \
            bash \
            bash-completion \
            curl \
            less \
            nano \
            procps \
            wget \
            which \
            vulkan-icd-loader \
            vulkan-tools \
            mesa-utils \
            git \
            fakeroot \
            base-devel \
            debugedit \
    && \
    # echo "**** Section cleanup ****" \
	#     && pacman -Scc --noconfirm \
    #     && rm -fr /var/lib/pacman/sync/* \
    #     && rm -fr /var/cache/pacman/pkg/* \
    # && \
    echo

# Install Wayland requirements
RUN \
    echo "**** Install Wayland requirements ****" \
        && pacman -Syu --noconfirm --needed \
            wayland \
            wayland-protocols \
            xorg-xwayland \
    && \
    # echo "**** Section cleanup ****" \
    #     && pacman -Scc --noconfirm \
    #     && rm -fr /var/lib/pacman/sync/* \
    #     && rm -fr /var/cache/pacman/pkg/* \
    # && \
    echo

# Setup audio management
RUN \
    echo "**** Install audio management ****" \
        && pacman -Syu --noconfirm --needed \
            pipewire \
            pipewire-pulse \
            wireplumber \
    && \
    # echo "**** Section cleanup ****" \
	#     && pacman -Scc --noconfirm \
    #     && rm -fr /var/lib/pacman/sync/* \
    #     && rm -fr /var/cache/pacman/pkg/* \
    # && \
    echo

# Setup video streaming deps
RUN \
    echo "**** Install video streaming deps ****" \
        && pacman -Syu --noconfirm --needed \
            libva \
            libva-mesa-driver \
            egl-wayland \
    && \
    # echo "**** Section cleanup ****" \
	#     && pacman -Scc --noconfirm \
    #     && rm -fr /var/lib/pacman/sync/* \
    #     && rm -fr /var/cache/pacman/pkg/* \
    # && \
    echo

# Install tools for monitoring hardware
RUN \
    echo "**** Install tools for monitoring hardware ****" \
        && pacman -Syu --noconfirm --needed \
            htop \
            libva-utils \
            vdpauinfo \
    && \
    # echo "**** Section cleanup ****" \
	#     && pacman -Scc --noconfirm \
    #     && rm -fr /var/lib/pacman/sync/* \
    #     && rm -fr /var/cache/pacman/pkg/* \
    # && \
    echo

# Install compositor
RUN \
    echo "**** Install compositor + seat manager ****" \
        && pacman -Syu --noconfirm --needed \
            libinput \
            clang \
            cmake \
            meson \
            ninja \
            glslang \
            vulkan-headers \
            seatd \
            libx11 \
            libxrandr \
            libxinerama \
            libxkbcommon \
            libxcursor \
            libxfixes \
            libxdamage \
            libxcomposite \
            libxres \
            libxmu \
            xcb-util-renderutil \
            xcb-util-wm \
            xcb-util-errors \
            libdisplay-info \
            libdecor \
            glm \
            ffmpeg \
            libxtst \
            luajit \
    && \
    # echo "**** Section cleanup ****" \
	#     && pacman -Scc --noconfirm \
    #     && rm -fr /var/lib/pacman/sync/* \
    #     && rm -fr /var/cache/pacman/pkg/* \
    # && \
    echo

RUN chmod u+s /usr/bin/seatd-launch

# Install Gamescope from repo
RUN \
    echo "**** Install Gamescope from repo ****" \
        && pacman -Syu --noconfirm --needed gamescope \
    && \
    echo

# Avoid steam installing the wrong vulkan dependencies
RUN \
    echo "**** Avoid steam installing the wrong vulkan dependencies ****" \
        && pacman -Syu --noconfirm --needed \
        vulkan-swrast \
        lib32-vulkan-swrast \
        ttf-liberation \
        --ignore vulkan-driver,lib32-vulkan-driver,nvidia-utils,lib32-nvidia-utils,amdvlk,lib32-amdvlk \
    && \
    # echo "**** Section cleanup ****" \
	#     && pacman -Scc --noconfirm \
    #     && rm -fr /var/lib/pacman/sync/* \
    #     && rm -fr /var/cache/pacman/pkg/* \
    # && \
    echo

# Install Steam
RUN \
    echo "**** Install Steam ****" \
	    && pacman -Syu --noconfirm --needed \
            steam \
    && \
    # echo "**** Section cleanup ****" \
	#     && pacman -Scc --noconfirm \
    #     && rm -fr /var/lib/pacman/sync/* \
    #     && rm -fr /var/cache/pacman/pkg/* \
    # && \
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
    && \
    # echo "**** Section cleanup ****" \
	#     && pacman -Scc --noconfirm \
    #     && rm -fr /var/lib/pacman/sync/* \
    #     && rm -fr /var/cache/pacman/pkg/* \
    # && \
    echo

RUN setcap cap_sys_admin,cap_sys_nice+ep $(readlink -f $(which gamescope)) \
    && setcap cap_sys_admin,cap_sys_nice+ep $(readlink -f $(which sunshine))

# After the line that already installs miniupnpc
RUN ln -s libminiupnpc.so /usr/lib/libminiupnpc.so.19

# Initialize Sunshine directories with correct permissions
RUN mkdir -p /home/steamshine/.config/sunshine && \
    chown -R steamshine:steamshine /home/steamshine/.config/sunshine && \
    chmod -R 755 /home/steamshine/.config/sunshine

# Create startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Set up volumes
VOLUME ["/home/steamshine/.steam", "/home/steamshine/.local/share/sunshine"]

# Switch to non-root user
USER steamshine
WORKDIR /home/steamshine

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/start.sh"] 