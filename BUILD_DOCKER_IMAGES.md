# Building NetBird Docker Images

This guide explains how to build Docker images for all NetBird components locally.

## Overview

NetBird consists of several components, each with its own Dockerfile:
- **Management** (`management/Dockerfile`) - Management API service
- **Signal** (`signal/Dockerfile`) - Signaling service for peer connections
- **Relay** (`relay/Dockerfile`) - TURN relay server
- **Client** (`client/Dockerfile` or `client/Dockerfile-rootless`) - NetBird client
- **Upload Server** (`upload-server/Dockerfile`) - File upload service

## Prerequisites

- Docker installed and running
- Go 1.23+ installed (for building binaries)
- Make sure you're in the repository root directory

## Build Process

The Dockerfiles expect pre-built binaries. You need to:
1. Build the Go binaries first
2. Then build the Docker images using those binaries

## Building Individual Components

### 1. Management Service

```bash
# Build the binary
cd management
go build -o netbird-mgmt .

# Build the Docker image
cd ..
docker build -f management/Dockerfile -t netbirdio/management:local \
  --build-arg NETBIRD_BINARY=netbird-mgmt \
  .
```

### 2. Signal Service

```bash
# Build the binary
cd signal
go build -o netbird-signal .

# Build the Docker image
cd ..
docker build -f signal/Dockerfile -t netbirdio/signal:local \
  --build-arg NETBIRD_BINARY=netbird-signal \
  .
```

### 3. Relay Service

```bash
# Build the binary
cd relay
go build -o netbird-relay .

# Build the Docker image
cd ..
docker build -f relay/Dockerfile -t netbirdio/relay:local \
  --build-arg NETBIRD_BINARY=netbird-relay \
  .
```

### 4. Client (Standard)

```bash
# Build the binary
cd client
CGO_ENABLED=0 go build -o netbird .

# Build the Docker image
cd ..
docker build -f client/Dockerfile -t netbirdio/netbird:local \
  --build-arg NETBIRD_BINARY=netbird \
  --ignorefile .dockerignore-client \
  .
```

### 5. Client (Rootless)

```bash
# Build the binary
cd client
CGO_ENABLED=0 go build -o netbird .

# Build the Docker image
cd ..
docker build -f client/Dockerfile-rootless -t netbirdio/netbird:local-rootless \
  --build-arg NETBIRD_BINARY=netbird \
  --ignorefile .dockerignore-client \
  .
```

### 6. Upload Server

```bash
# Build the binary
cd upload-server
go build -o netbird-upload .

# Build the Docker image
cd ..
docker build -f upload-server/Dockerfile -t netbirdio/upload-server:local \
  --build-arg NETBIRD_BINARY=netbird-upload \
  .
```

## Building All Images at Once

You can use this script to build all components:

```bash
#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building NetBird Docker images...${NC}"

# Build Management
echo -e "${GREEN}Building Management service...${NC}"
cd management
go build -o netbird-mgmt .
cd ..
docker build -f management/Dockerfile -t netbirdio/management:local \
  --build-arg NETBIRD_BINARY=netbird-mgmt . || true

# Build Signal
echo -e "${GREEN}Building Signal service...${NC}"
cd signal
go build -o netbird-signal .
cd ..
docker build -f signal/Dockerfile -t netbirdio/signal:local \
  --build-arg NETBIRD_BINARY=netbird-signal . || true

# Build Relay
echo -e "${GREEN}Building Relay service...${NC}"
cd relay
go build -o netbird-relay .
cd ..
docker build -f relay/Dockerfile -t netbirdio/relay:local \
  --build-arg NETBIRD_BINARY=netbird-relay . || true

# Build Client
echo -e "${GREEN}Building Client...${NC}"
cd client
CGO_ENABLED=0 go build -o netbird .
cd ..
docker build -f client/Dockerfile -t netbirdio/netbird:local \
  --build-arg NETBIRD_BINARY=netbird \
  --ignorefile .dockerignore-client . || true

# Build Upload Server
echo -e "${GREEN}Building Upload Server...${NC}"
cd upload-server
go build -o netbird-upload .
cd ..
docker build -f upload-server/Dockerfile -t netbirdio/upload-server:local \
  --build-arg NETBIRD_BINARY=netbird-upload . || true

echo -e "${GREEN}All images built successfully!${NC}"
echo ""
echo "Built images:"
docker images | grep "netbirdio/.*:local"
```

Save this as `build-docker-images.sh`, make it executable (`chmod +x build-docker-images.sh`), and run it.

## Using Multi-Stage Builds (Alternative)

If you prefer to build everything in Docker without pre-building binaries, you can modify the Dockerfiles to use multi-stage builds. However, the current Dockerfiles are optimized for the release process using Goreleaser.

## Building for Specific Platforms

To build for specific architectures (e.g., ARM64):

```bash
# Example: Build management service for ARM64
docker buildx build --platform linux/arm64 \
  -f management/Dockerfile \
  -t netbirdio/management:local-arm64 \
  --build-arg NETBIRD_BINARY=netbird-mgmt \
  .
```

For multi-platform builds:

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -f management/Dockerfile \
  -t netbirdio/management:local \
  --build-arg NETBIRD_BINARY=netbird-mgmt \
  .
```

## Using Built Images with docker-compose

After building your images, update your `docker-compose.yml` to use the local tags:

```yaml
services:
  management:
    image: netbirdio/management:local  # Instead of netbirdio/management:$NETBIRD_MANAGEMENT_TAG
    # ... rest of config
```

Or override the image tag when running docker-compose:

```bash
NETBIRD_MANAGEMENT_TAG=local \
NETBIRD_SIGNAL_TAG=local \
NETBIRD_RELAY_TAG=local \
docker-compose up -d
```

## Troubleshooting

### Binary not found errors
- Make sure you've built the binary before building the Docker image
- Check that the binary name matches the `NETBIRD_BINARY` build arg
- Ensure you're running the docker build from the repository root

### Permission errors (Client)
- The client Dockerfile requires `NET_ADMIN`, `NET_RAW`, and `BPF` capabilities
- Use `sudo` if needed, or ensure your user is in the docker group

### Build context issues
- Always run `docker build` from the repository root
- The Dockerfiles expect to copy binaries from the current directory

## Pushing to ProGet Registry

NetBird images can be pushed to your ProGet container registry at `proget.terra-net.io`.

### Prerequisites

1. **Login to ProGet**:
   ```bash
   docker login proget.terra-net.io
   ```
   You'll be prompted for your ProGet username and password.

2. **Configure the feed name** (if different from default):
   ```bash
   export PROGET_FEED=your-feed-name  # Default is "images"
   ```

### Building and Tagging for ProGet

**Option 1: Build with automatic tagging for ProGet**
```bash
export PROGET_REGISTRY=proget.terra-net.io
export PROGET_FEED=images  # Change if your feed has a different name
export IMAGE_TAG=latest    # or any tag you prefer
export PUSH_IMAGES=true    # This tags images for ProGet

./build-docker-images.sh
```

**Option 2: Build normally, then tag manually**
```bash
# Build images
./build-docker-images.sh

# Tag for ProGet
docker tag netbirdio/management:local proget.terra-net.io/images/netbirdio/management:latest
docker tag netbirdio/signal:local proget.terra-net.io/images/netbirdio/signal:latest
docker tag netbirdio/relay:local proget.terra-net.io/images/netbirdio/relay:latest
docker tag netbirdio/netbird:local proget.terra-net.io/images/netbirdio/netbird:latest
docker tag netbirdio/upload-server:local proget.terra-net.io/images/netbirdio/upload-server:latest
```

### Pushing to ProGet

Use the provided push script:
```bash
export PROGET_REGISTRY=proget.terra-net.io
export PROGET_FEED=images
export IMAGE_TAG=latest

./push-to-proget.sh
```

Or push manually:
```bash
docker push proget.terra-net.io/images/netbirdio/management:latest
docker push proget.terra-net.io/images/netbirdio/signal:latest
docker push proget.terra-net.io/images/netbirdio/relay:latest
docker push proget.terra-net.io/images/netbirdio/netbird:latest
docker push proget.terra-net.io/images/netbirdio/upload-server:latest
```

### Using ProGet Images in docker-compose

Update your `docker-compose.yml` or environment variables:

```bash
export NETBIRD_MANAGEMENT_TAG=latest
export NETBIRD_SIGNAL_TAG=latest
export NETBIRD_RELAY_TAG=latest
```

And update `docker-compose.yml.tmpl` to use ProGet registry:
```yaml
services:
  management:
    image: proget.terra-net.io/images/netbirdio/management:${NETBIRD_MANAGEMENT_TAG}
  signal:
    image: proget.terra-net.io/images/netbirdio/signal:${NETBIRD_SIGNAL_TAG}
  relay:
    image: proget.terra-net.io/images/netbirdio/relay:${NETBIRD_RELAY_TAG}
```

### ProGet Feed Configuration

The default feed name is `images`. If your ProGet instance uses a different feed name for Docker images, set it via:
```bash
export PROGET_FEED=your-feed-name
```

To find your feed name:
1. Log into ProGet at https://proget.terra-net.io/
2. Navigate to **Feeds** → **Docker** (or **Images**)
3. The feed name is shown in the URL or feed list

## Notes

- The official release process uses [Goreleaser](https://goreleaser.com/) which handles building binaries and Docker images automatically
- For development, building locally as shown above is sufficient
- The `CGO_ENABLED=0` flag for the client ensures a static binary that works in Alpine Linux containers
- ProGet uses standard Docker registry API, so standard `docker push` commands work

