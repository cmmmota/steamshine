# Steamshine

A containerized game streaming solution using [Sunshine](https://github.com/LizardByte/Sunshine) and Steam, optimized for AMD RDNA4 GPUs. Run your games in headless containers and stream them to any Moonlight client.

## Architecture

The project consists of two Docker images that work together:

### Gaming Session (`gaming-session`)

A headless Wayland gaming environment based on Arch Linux featuring:

- **Sway** compositor running in headless mode
- **Steam** with official runtime
- **Gamescope** for game session management
- **PipeWire** for modern audio handling
- **Mesa-git** from CachyOS repos for latest RDNA4 support (gfx1201)
- **MangoHud** and **GameMode** for performance optimization

### Sunshine Server (`sunshine-server`)

A Sunshine streaming server that captures from the gaming session:

- **Sunshine** built from source with Wayland support
- **VA-API** hardware encoding for AMD GPUs
- **kubectl** for Kubernetes pod management (optional)

## Requirements

- Docker or Podman
- AMD GPU with Vulkan support (optimized for RDNA4)
- `/dev/dri` device access for GPU passthrough

## Quick Start

### Pull the images

```bash
docker pull ghcr.io/cmmmota/gaming-session:latest
docker pull ghcr.io/cmmmota/sunshine-server:latest
```

### Build locally

```bash
# Build gaming session
docker build -t gaming-session:latest ./gaming-session

# Build sunshine server
docker build -t sunshine-server:latest ./sunshine-server
```

### Run the containers

Both containers need access to the GPU and a shared XDG runtime directory for Wayland socket communication.

```bash
# Create shared runtime directory
mkdir -p /tmp/steamshine-xdg
chmod 0700 /tmp/steamshine-xdg

# Run gaming session
docker run -d \
  --name gaming-session \
  --device /dev/dri \
  --privileged \
  -v /tmp/steamshine-xdg:/xdg \
  -v steam-data:/home/gamer/.local/share/Steam \
  gaming-session:latest

# Run sunshine server
docker run -d \
  --name sunshine-server \
  --device /dev/dri \
  --privileged \
  -v /tmp/steamshine-xdg:/xdg \
  -p 47984:47984/tcp \
  -p 47989:47989/tcp \
  -p 47990:47990/tcp \
  -p 48010:48010/tcp \
  -p 47998:47998/udp \
  -p 47999:47999/udp \
  -p 48000:48000/udp \
  -p 48002:48002/udp \
  -p 48010:48010/udp \
  sunshine-server:latest
```

## Configuration

### Gaming Session

The Sway compositor is configured for headless operation at 1920x1080@60Hz. You can customize this by mounting your own config:

```bash
-v /path/to/your/sway-config:/home/gamer/.config/sway/config
```

### Sunshine Server

Mount a custom `apps.json` to configure available applications:

```bash
-v /path/to/apps.json:/config/apps.json
```

The default Sunshine configuration uses:
- VA-API encoding via `/dev/dri/renderD128`
- Wayland capture only (no X11)
- Web UI accessible from WAN

### Environment Variables

#### Gaming Session

| Variable | Default | Description |
|----------|---------|-------------|
| `WLR_BACKENDS` | `headless` | Wayland backend type |
| `WAYLAND_DISPLAY` | `wayland-0` | Wayland display name |
| `AMD_VULKAN_ICD` | `RADV` | Vulkan ICD loader |
| `RADV_PERFTEST` | `gpl` | RADV performance options |

#### Sunshine Server

| Variable | Default | Description |
|----------|---------|-------------|
| `WAYLAND_DISPLAY` | `wayland-0` | Wayland display to capture |
| `XDG_RUNTIME_DIR` | `/xdg` | XDG runtime directory |

## Ports

The Sunshine server exposes the following ports:

| Port | Protocol | Purpose |
|------|----------|---------|
| 47984 | TCP | HTTPS/Web UI |
| 47989 | TCP | HTTP |
| 47990 | TCP | Web UI |
| 48010 | TCP/UDP | RTSP |
| 47998-48000 | UDP | Video/Audio/Control |
| 48002 | UDP | Control |

## Connecting with Moonlight

1. Open [Moonlight](https://moonlight-stream.org/) on your client device
2. Add your server's IP address
3. Pair with the PIN shown in Sunshine's web UI (`https://<server-ip>:47990`)
4. Launch your games!

## Kubernetes Deployment

This project is designed with Kubernetes in mind. The containers include `kubectl` for orchestration scenarios where:

- Gaming sessions are started on-demand when a user connects
- Sessions can be scaled down when idle
- Multiple users can have isolated gaming environments

## GPU Compatibility

Optimized for AMD GPUs with special attention to RDNA4 (RX 9000 series):

- Uses Mesa-git from CachyOS repositories
- Includes gfx1201 support for RX 9070 XT
- Falls back gracefully on older AMD GPUs

## License

MIT

## Acknowledgments

- [Sunshine](https://github.com/LizardByte/Sunshine) - The self-hosted game streaming server
- [Gamescope](https://github.com/ValveSoftware/gamescope) - Valve's micro-compositor
- [CachyOS](https://cachyos.org/) - For bleeding-edge Mesa packages
