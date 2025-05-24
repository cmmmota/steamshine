# SteamShine

A Docker container that combines Steam and Sunshine for game streaming.

## Requirements

### Host System Requirements
- Docker with NVIDIA Container Toolkit installed
- NVIDIA GPU with appropriate drivers
- Docker Compose (for local development)
- Kubernetes cluster with NVIDIA device plugin (for production)

### NVIDIA Container Toolkit Setup
```bash
# Add NVIDIA package repositories
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install NVIDIA Container Toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Restart Docker daemon
sudo systemctl restart docker
```

## Persistent Storage

The container uses two persistent volumes:

- `steamshine-steam-data`: Stores Steam games and user data
- `steamshine-sunshine-config`: Stores Sunshine configuration

## Usage

```bash
# Start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

## Volume Locations

- Steam data: `/home/steamshine/.steam`
- Sunshine config: `/home/steamshine/.config/sunshine`

## Troubleshooting

### NVIDIA Container Toolkit Issues
If you see the error "NVIDIA Container Toolkit not found", ensure:
1. NVIDIA Container Toolkit is installed on the host
2. Docker is configured to use the NVIDIA runtime
3. Host system has compatible NVIDIA drivers

### GPU Access Issues
If the container cannot access the GPU:
1. Verify `nvidia-smi` works on the host
2. Check if the container is running with `--gpus all`
3. Ensure the host's NVIDIA drivers are compatible with the container's requirements