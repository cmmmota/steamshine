FROM lizardbyte/sunshine:v2025.524.144138-debian-bookworm@sha256:b95de5d12a7cda3d38117562294d9700c5025fb5eda42b63eea1b6ed65187a77 AS base

# Build stage
FROM base AS builder
RUN apt-get update && apt-get install -y \
    steam-launcher \
    nvidia-driver \
    nvidia-container-toolkit \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Final stage
FROM base
COPY --from=builder /usr/bin/steam /usr/bin/steam
COPY --from=builder /usr/lib/nvidia* /usr/lib/
COPY --from=builder /usr/lib32/nvidia* /usr/lib32/

# Create non-root user
RUN useradd -m -s /bin/bash steamshine

# NVIDIA runtime configuration
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

# Verify NVIDIA Container Toolkit
RUN if [ ! -f /usr/bin/nvidia-container-cli ]; then \
        echo "NVIDIA Container Toolkit not found. Please ensure it is installed on the host system."; \
        exit 1; \
    fi

# Security configurations
ENV HOME=/home/steamshine
WORKDIR $HOME

# Copy and set up startup script
COPY start.sh /start.sh
RUN chmod 755 /start.sh && \
    chown steamshine:steamshine /start.sh

# Switch to non-root user
USER steamshine

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep -f "steam|sunshine" || exit 1

ENTRYPOINT ["/start.sh"]