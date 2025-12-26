# Pushing NetBird Images to ProGet

Quick guide for building and pushing NetBird Docker images to your ProGet registry at `proget.terra-net.io`.

## Quick Start

```bash
# 1. Login to ProGet
docker login proget.terra-net.io

# 2. Build and tag images for ProGet
export PROGET_REGISTRY=proget.terra-net.io
export PROGET_FEED=images  # Change if your feed name is different
export IMAGE_TAG=latest    # or use a version like "v1.0.0"
export PUSH_IMAGES=true

./build-docker-images.sh

# 3. Push to ProGet
./push-to-proget.sh
```

## Step-by-Step

### 1. Authenticate with ProGet

```bash
docker login proget.terra-net.io
```

Enter your ProGet username and password when prompted.

### 2. Configure Environment Variables

```bash
# ProGet registry URL
export PROGET_REGISTRY=proget.terra-net.io

# Docker feed name (check in ProGet UI if unsure)
export PROGET_FEED=images

# Image tag to use
export IMAGE_TAG=latest
```

**Finding your feed name:**
- Log into ProGet at https://proget.terra-net.io/
- Go to **Feeds** → **Docker** (or **Images**)
- The feed name is typically `images` but may vary

### 3. Build Images

**Option A: Build with automatic ProGet tagging**
```bash
export PUSH_IMAGES=true
./build-docker-images.sh
```

**Option B: Build normally, tag later**
```bash
./build-docker-images.sh
```

### 4. Push Images

```bash
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

## Using ProGet Images

### Option 1: Use the ProGet Template (Recommended)

A ProGet-specific template is available at `infrastructure_files/docker-compose.yml.tmpl.proget`. To use it:

```bash
cd infrastructure_files
# Copy the ProGet template as the main template
cp docker-compose.yml.tmpl.proget docker-compose.yml.tmpl
# Run configure.sh as usual
./configure.sh
```

### Option 2: Manually Update docker-compose.yml.tmpl

Edit `infrastructure_files/docker-compose.yml.tmpl`:

```yaml
services:
  management:
    image: proget.terra-net.io/images/netbirdio/management:${NETBIRD_MANAGEMENT_TAG}
  signal:
    image: proget.terra-net.io/images/netbirdio/signal:${NETBIRD_SIGNAL_TAG}
  relay:
    image: proget.terra-net.io/images/netbirdio/relay:${NETBIRD_RELAY_TAG}
  dashboard:
    image: proget.terra-net.io/images/netbirdio/dashboard:${NETBIRD_DASHBOARD_TAG}
```

### Set Environment Variables

In your `setup.env` or when running docker-compose:

```bash
export NETBIRD_MANAGEMENT_TAG=latest
export NETBIRD_SIGNAL_TAG=latest
export NETBIRD_RELAY_TAG=latest
```

### Pull Images

Docker will automatically pull from ProGet when you run docker-compose:

```bash
cd infrastructure_files
docker-compose pull
docker-compose up -d
```

## Image Names

Images will be pushed with the following names:
- `proget.terra-net.io/images/netbirdio/management:<tag>`
- `proget.terra-net.io/images/netbirdio/signal:<tag>`
- `proget.terra-net.io/images/netbirdio/relay:<tag>`
- `proget.terra-net.io/images/netbirdio/netbird:<tag>`
- `proget.terra-net.io/images/netbirdio/upload-server:<tag>`

**Note:** The dashboard image (`netbirdio/dashboard`) is a separate project and is not built by our scripts. To use it from ProGet:

```bash
# Pull dashboard from Docker Hub and push to ProGet
DASHBOARD_TAG=latest ./pull-push-dashboard.sh
```

Or manually:
```bash
docker pull netbirdio/dashboard:latest
docker tag netbirdio/dashboard:latest proget.terra-net.io/images/netbirdio/dashboard:latest
docker push proget.terra-net.io/images/netbirdio/dashboard:latest
```

## Troubleshooting

### Authentication Failed
```bash
# Re-login
docker logout proget.terra-net.io
docker login proget.terra-net.io
```

### Feed Not Found
- Verify the feed name in ProGet UI
- Ensure the feed is configured for Docker images
- Check feed permissions

### Push Permission Denied
- Verify your ProGet user has push permissions for the feed
- Contact ProGet administrator if needed

### Image Not Found Locally
```bash
# List local images
docker images | grep netbirdio

# Rebuild if needed
./build-docker-images.sh
```

## Advanced: Custom Tags

To push multiple tags:

```bash
# Build once
./build-docker-images.sh

# Tag with multiple versions
docker tag netbirdio/management:local proget.terra-net.io/images/netbirdio/management:latest
docker tag netbirdio/management:local proget.terra-net.io/images/netbirdio/management:v1.0.0
docker tag netbirdio/management:local proget.terra-net.io/images/netbirdio/management:$(git rev-parse --short HEAD)

# Push all tags
docker push proget.terra-net.io/images/netbirdio/management:latest
docker push proget.terra-net.io/images/netbirdio/management:v1.0.0
docker push proget.terra-net.io/images/netbirdio/management:$(git rev-parse --short HEAD)
```

## Verification

After pushing, verify images are available:

```bash
# List images in ProGet (if API is accessible)
curl -u username:password https://proget.terra-net.io/api/docker/images/v2/_catalog

# Or check in ProGet UI
# Navigate to: Feeds → Docker (or Images) → Packages
```

