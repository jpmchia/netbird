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

# Get the repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo -e "${BLUE}Pushing NetBird Docker images to ProGet...${NC}"
echo -e "${BLUE}Registry: ${REGISTRY}${NC}"
echo -e "${BLUE}Feed: ${FEED}${NC}"
echo -e "${BLUE}Tag: ${TAG}${NC}"
echo ""

# Check if logged in
if ! docker info | grep -q "Username"; then
  echo -e "${YELLOW}Not logged in to Docker. Attempting login to ${REGISTRY}...${NC}"
  echo -e "${YELLOW}You will be prompted for your ProGet credentials.${NC}"
  docker login ${REGISTRY} || {
    echo -e "${RED}Failed to login to ${REGISTRY}${NC}"
    echo -e "${YELLOW}Please run: docker login ${REGISTRY}${NC}"
    exit 1
  }
fi

# List of images to push
IMAGES=(
  "netbirdio/management:${TAG}"
  "netbirdio/signal:${TAG}"
  "netbirdio/relay:${TAG}"
  "netbirdio/netbird:${TAG}"
  "netbirdio/upload-server:${TAG}"
)

# Push each image
for image in "${IMAGES[@]}"; do
  # Check if image exists locally
  if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
    echo -e "${YELLOW}Image ${image} not found locally, skipping...${NC}"
    continue
  fi

  # Tag for ProGet
  proget_image="${REGISTRY}/${FEED}/${image}"
  
  echo -e "${GREEN}Pushing ${image} -> ${proget_image}...${NC}"
  
  # Tag if not already tagged
  if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${proget_image}$"; then
    docker tag "${image}" "${proget_image}" || {
      echo -e "${RED}Failed to tag ${image}${NC}"
      continue
    }
  fi
  
  # Push
  docker push "${proget_image}" || {
    echo -e "${RED}Failed to push ${proget_image}${NC}"
    continue
  }
  
  echo -e "${GREEN}✓ Successfully pushed ${proget_image}${NC}"
done

echo ""
echo -e "${GREEN}Push complete!${NC}"
echo ""
echo "Pushed images:"
docker images | grep "${REGISTRY}/${FEED}/netbirdio" || echo "No ProGet images found"

echo ""
echo -e "${BLUE}To use these images in docker-compose, set:${NC}"
echo "  NETBIRD_MANAGEMENT_TAG=${TAG}"
echo "  NETBIRD_SIGNAL_TAG=${TAG}"
echo "  NETBIRD_RELAY_TAG=${TAG}"
echo ""
echo -e "${BLUE}And update docker-compose.yml to use:${NC}"
echo "  image: ${REGISTRY}/${FEED}/netbirdio/management:\${NETBIRD_MANAGEMENT_TAG}"

