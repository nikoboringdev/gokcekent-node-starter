#!/bin/bash
set -e

# Configuration
REMOTE_HOST=${REMOTE_HOST:-"157.180.18.40"}
REMOTE_PORT=${REMOTE_PORT:-"2222"}
CONTAINER_NAME=${CONTAINER_NAME:-"node-starter-api"}

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Function to setup SSH key in container
setup_ssh_key() {
    echo -e "${BLUE}🔑 Setting up SSH key in container...${NC}"
    
    # Generate key if it doesn't exist
    if [ ! -f "./deploy_key" ]; then
        ssh-keygen -t rsa -b 4096 -f ./deploy_key -N ""
        chmod 600 deploy_key
        chmod 644 deploy_key.pub
    fi

    # Copy key to remote host
    ssh-copy-id -i deploy_key -p ${REMOTE_PORT} root@${REMOTE_HOST} || {
        echo -e "${RED}Failed to copy SSH key to remote host${NC}"
        exit 1
    }

    # Add key to container's authorized_keys
    ssh -i deploy_key -p ${REMOTE_PORT} root@${REMOTE_HOST} "
        docker exec ${CONTAINER_NAME} mkdir -p /root/.ssh && \
        docker cp deploy_key.pub ${CONTAINER_NAME}:/root/.ssh/authorized_keys && \
        docker exec ${CONTAINER_NAME} chmod 700 /root/.ssh && \
        docker exec ${CONTAINER_NAME} chmod 600 /root/.ssh/authorized_keys
    "
    
    echo -e "${GREEN}✅ SSH key setup complete${NC}"
}

# Function to sync dist folder
sync_dist() {
    echo -e "${BLUE}🔄 Syncing dist folder...${NC}"
    rsync -avz -e "ssh -p ${REMOTE_PORT} -i deploy_key" \
        --exclude 'node_modules' \
        ./dist/ \
        root@${REMOTE_HOST}:/var/lib/docker/volumes/${CONTAINER_NAME}_dist/_data/

    # Update permissions after sync
    ssh -i deploy_key -p ${REMOTE_PORT} root@${REMOTE_HOST} "
        docker exec ${CONTAINER_NAME} chown -R node:node /usr/src/app/dist
    "
    
    echo -e "${GREEN}✅ Sync complete${NC}"
}

# Function to watch and build
watch_and_build() {
    echo -e "${BLUE}👀 Watching for changes...${NC}"
    nodemon --watch 'src/**/*.ts' --exec 'npm run build && npm run sync:dist' --ext ts
}

# Function to verify SSH connection
verify_ssh() {
    echo -e "${BLUE}🔍 Verifying SSH connection...${NC}"
    ssh -i deploy_key -p ${REMOTE_PORT} -o BatchMode=yes -o ConnectTimeout=5 root@${REMOTE_HOST} echo "SSH connection successful" >/dev/null 2>&1 || {
        echo -e "${RED}SSH connection failed. Running setup...${NC}"
        # setup_ssh_key
    }
}

case "$1" in
    init)
        setup_ssh_key
        ;;
    build)
        npm run build
        ;;
    sync:dist)
        verify_ssh
        sync_dist
        ;;
    dev)
        verify_ssh
        watch_and_build
        ;;
    logs)
        verify_ssh
        ssh -i deploy_key -p ${REMOTE_PORT} root@${REMOTE_HOST} \
            "docker logs -f ${CONTAINER_NAME}"
        ;;
    *)
        echo -e "${RED}Usage: $0 {init|build|sync:dist|dev|logs}${NC}"
        exit 1
        ;;
esac 