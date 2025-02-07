#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Initializing development environment...${NC}"

# Generate SSH key if it doesn't exist
if [ ! -f "./deploy_key" ]; then
    echo -e "${BLUE}🔑 Generating SSH key...${NC}"
    ssh-keygen -t rsa -b 4096 -f ./deploy_key -N ""
    chmod 600 deploy_key
    chmod 644 deploy_key.pub
    echo -e "${GREEN}✅ SSH key generated${NC}"
    echo -e "${BLUE}📋 Your public key (add this to remote machine):${NC}"
    cat deploy_key.pub
fi

# Build and push dev image
echo -e "${BLUE}📦 Building development image...${NC}"
./deploy.sh dev

echo -e "${GREEN}✅ Development environment initialized${NC}" 