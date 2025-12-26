#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
REGISTRY="${PROGET_REGISTRY:-proget.terra-net.io}"
FEED="${PROGET_FEED:-images}"
TAG="${IMAGE_TAG:-local}"
PUSH="${PUSH_IMAGES:-false}"

# Get the repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# Cleanup function to remove temporary binaries and restore .dockerignore
cleanup() {
  rm -f ./netbird-mgmt ./netbird-signal ./netbird-relay ./netbird ./netbird-upload
  if [ -f .dockerignore-client ] && [ -f .dockerignore ] && ! cmp -s .dockerignore-client .dockerignore; then
    # .dockerignore was modified, restore backup if it exists
    if [ -f .dockerignore.bak ]; then
      mv .dockerignore.bak .dockerignore
    else
      rm -f .dockerignore
    fi
  fi
}
trap cleanup EXIT

echo -e "${BLUE}Building NetBird Docker images...${NC}"
if [ "$PUSH" = "true" ]; then
  echo -e "${BLUE}Registry: ${REGISTRY}${NC}"
  echo -e "${BLUE}Feed: ${FEED}${NC}"
fi
echo -e "${BLUE}Tag: ${TAG}${NC}"
echo ""

# Build Management
echo -e "${GREEN}[1/5] Building Management service...${NC}"
cd management
CGO_ENABLED=1 go build -o netbird-mgmt .
cd ..
cp management/netbird-mgmt ./netbird-mgmt || {
  echo -e "${RED}Failed to copy management binary${NC}"
  exit 1
}
docker build -f management/Dockerfile -t netbirdio/management:${TAG} \
  --build-arg NETBIRD_BINARY=netbird-mgmt . || {
  echo -e "${YELLOW}Warning: Failed to build management image${NC}"
}
rm -f ./netbird-mgmt
if [ "$PUSH" = "true" ]; then
  docker tag netbirdio/management:${TAG} ${REGISTRY}/${FEED}/netbirdio/management:${TAG}
fi

# Build Signal
echo -e "${GREEN}[2/5] Building Signal service...${NC}"
cd signal
go build -o netbird-signal .
cd ..
cp signal/netbird-signal ./netbird-signal || {
  echo -e "${RED}Failed to copy signal binary${NC}"
  exit 1
}
docker build -f signal/Dockerfile -t netbirdio/signal:${TAG} \
  --build-arg NETBIRD_BINARY=netbird-signal . || {
  echo -e "${YELLOW}Warning: Failed to build signal image${NC}"
}
rm -f ./netbird-signal
if [ "$PUSH" = "true" ]; then
  docker tag netbirdio/signal:${TAG} ${REGISTRY}/${FEED}/netbirdio/signal:${TAG}
fi

# Build Relay
echo -e "${GREEN}[3/5] Building Relay service...${NC}"
cd relay
go build -o netbird-relay .
cd ..
cp relay/netbird-relay ./netbird-relay || {
  echo -e "${RED}Failed to copy relay binary${NC}"
  exit 1
}
docker build -f relay/Dockerfile -t netbirdio/relay:${TAG} \
  --build-arg NETBIRD_BINARY=netbird-relay . || {
  echo -e "${YELLOW}Warning: Failed to build relay image${NC}"
}
rm -f ./netbird-relay
if [ "$PUSH" = "true" ]; then
  docker tag netbirdio/relay:${TAG} ${REGISTRY}/${FEED}/netbirdio/relay:${TAG}
fi

# Build Client
echo -e "${GREEN}[4/5] Building Client...${NC}"
cd client
CGO_ENABLED=0 go build -o netbird .
cd ..
cp client/netbird ./netbird || {
  echo -e "${RED}Failed to copy client binary${NC}"
  exit 1
}
# Use .dockerignore-client if it exists by temporarily copying it to .dockerignore
if [ -f .dockerignore-client ]; then
  # Backup existing .dockerignore if it exists
  if [ -f .dockerignore ]; then
    cp .dockerignore .dockerignore.bak
  fi
  cp .dockerignore-client .dockerignore
fi
docker build -f client/Dockerfile -t netbirdio/netbird:${TAG} \
  --build-arg NETBIRD_BINARY=netbird . || {
  echo -e "${YELLOW}Warning: Failed to build client image${NC}"
}
# Restore original .dockerignore if we backed it up
if [ -f .dockerignore-client ]; then
  rm -f .dockerignore
  if [ -f .dockerignore.bak ]; then
    mv .dockerignore.bak .dockerignore
  fi
fi
rm -f ./netbird
if [ "$PUSH" = "true" ]; then
  docker tag netbirdio/netbird:${TAG} ${REGISTRY}/${FEED}/netbirdio/netbird:${TAG}
fi

# Build Upload Server
echo -e "${GREEN}[5/5] Building Upload Server...${NC}"
cd upload-server
go build -o netbird-upload .
cd ..
cp upload-server/netbird-upload ./netbird-upload || {
  echo -e "${RED}Failed to copy upload-server binary${NC}"
  exit 1
}
docker build -f upload-server/Dockerfile -t netbirdio/upload-server:${TAG} \
  --build-arg NETBIRD_BINARY=netbird-upload . || {
  echo -e "${YELLOW}Warning: Failed to build upload-server image${NC}"
}
rm -f ./netbird-upload
if [ "$PUSH" = "true" ]; then
  docker tag netbirdio/upload-server:${TAG} ${REGISTRY}/${FEED}/netbirdio/upload-server:${TAG}
fi

echo ""
echo -e "${GREEN}Build complete!${NC}"
echo ""
echo "Built images:"
docker images | grep "netbirdio/.*:${TAG}" || echo "No images found with tag ${TAG}"

if [ "$PUSH" = "true" ]; then
  echo ""
  echo -e "${BLUE}Tagged images for ProGet:${NC}"
  docker images | grep "${REGISTRY}/${FEED}/netbirdio" || echo "No ProGet-tagged images found"
  echo ""
  echo -e "${YELLOW}To push images, run:${NC}"
  echo "  ./push-to-proget.sh"
fi

