#!/bin/bash
set -e

REMOTE_HOST=${1:-"your-remote-host"}
REMOTE_PORT=${2:-"2222"}

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔌 Connecting to remote host...${NC}"

ssh -i deploy_key -p ${REMOTE_PORT} root@${REMOTE_HOST}

echo -e "${GREEN}✅ Connection closed${NC}" 