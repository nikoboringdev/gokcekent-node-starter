#!/bin/bash
set -e

CONTAINER_NAME=${1:-"node-dev"}

# Colors for output
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📋 Showing logs...${NC}"

docker logs -f ${CONTAINER_NAME} 