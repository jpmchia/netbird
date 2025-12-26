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
DASHBOARD_TAG="${DASHBOARD_TAG:-latest}"
SOURCE_REGISTRY="${SOURCE_REGISTRY:-docker.io}"

echo -e "${BLUE}Pulling and pushing NetBird Dashboard to ProGet...${NC}"
echo -e "${BLUE}Source: ${SOURCE_REGISTRY}/netbirdio/dashboard:${DASHBOARD_TAG}${NC}"
echo -e "${BLUE}Destination: ${REGISTRY}/${FEED}/netbirdio/dashboard:${DASHBOARD_TAG}${NC}"
echo ""

# Pull dashboard from Docker Hub
echo -e "${GREEN}Pulling dashboard from Docker Hub...${NC}"
docker pull ${SOURCE_REGISTRY}/netbirdio/dashboard:${DASHBOARD_TAG} || {
  echo -e "${RED}Failed to pull dashboard image${NC}"
  exit 1
}

# Tag for ProGet
proget_image="${REGISTRY}/${FEED}/netbirdio/dashboard:${DASHBOARD_TAG}"
echo -e "${GREEN}Tagging for ProGet...${NC}"
docker tag ${SOURCE_REGISTRY}/netbirdio/dashboard:${DASHBOARD_TAG} ${proget_image} || {
  echo -e "${RED}Failed to tag dashboard image${NC}"
  exit 1
}

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

# Push to ProGet
echo -e "${GREEN}Pushing dashboard to ProGet...${NC}"
docker push ${proget_image} || {
  echo -e "${RED}Failed to push dashboard image${NC}"
  exit 1
}

echo ""
echo -e "${GREEN}✓ Successfully pushed ${proget_image}${NC}"
echo ""
echo -e "${BLUE}Dashboard is now available in ProGet at:${NC}"
echo "  ${proget_image}"

