#!/bin/bash
set -e

REMOTE_HOST=${1:-"your-remote-host"}
REMOTE_PORT=${2:-"2222"}
REMOTE_PATH="/usr/src/app"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 Syncing project to remote host...${NC}"

# Exclude patterns
EXCLUDES="--exclude '.git' --exclude 'node_modules' --exclude 'dist' --exclude 'deploy_key*'"

# Use rsync to sync files
rsync -avz -e "ssh -p ${REMOTE_PORT} -i deploy_key" \
    ${EXCLUDES} \
    ./ \
    root@${REMOTE_HOST}:${REMOTE_PATH}/

echo -e "${GREEN}✅ Sync complete${NC}" 