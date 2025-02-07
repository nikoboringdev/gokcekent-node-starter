#!/bin/bash
set -e

# Default values
REMOTE_HOST=${REMOTE_HOST:-"your-remote-host"}
REMOTE_PORT=${REMOTE_PORT:-"2222"}
CONTAINER_NAME=${CONTAINER_NAME:-"node-dev"}

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Help message
show_help() {
    echo -e "${BLUE}Remote Container Development${NC}"
    echo
    echo "Usage:"
    echo "  ./dev.sh [command]"
    echo
    echo "Commands:"
    echo "  sync     - Sync local files to container"
    echo "  watch    - Start file watcher for auto-sync"
    echo "  logs     - Show container logs"
    echo "  shell    - Get shell access to container"
    echo "  help     - Show this help message"
    echo
    echo "Environment variables:"
    echo "  REMOTE_HOST     - Remote host address"
    echo "  CONTAINER_NAME  - Container name in Portainer"
}

# Function to sync files to container
sync_files() {
    echo -e "${BLUE}🔄 Syncing files to container...${NC}"
    rsync -avz -e "ssh -p ${REMOTE_PORT} -i deploy_key" \
        --exclude '.git' \
        --exclude 'node_modules' \
        --exclude 'dist' \
        --exclude 'deploy_key*' \
        ./src/ \
        root@${REMOTE_HOST}:/var/lib/docker/volumes/your_project_node_modules/_data/src/
    
    echo -e "${GREEN}✅ Sync complete${NC}"
}

# Command handling
case "$1" in
    sync)
        sync_files
        ;;
    watch)
        echo -e "${BLUE}👀 Watching for changes...${NC}"
        while inotifywait -r -e modify,create,delete,move ./src; do
            sync_files
        done
        ;;
    logs)
        echo -e "${BLUE}📋 Fetching logs...${NC}"
        ssh -i deploy_key -p ${REMOTE_PORT} root@${REMOTE_HOST} \
            "docker logs -f ${CONTAINER_NAME}"
        ;;
    shell)
        echo -e "${BLUE}🐚 Connecting to container shell...${NC}"
        ssh -i deploy_key -p ${REMOTE_PORT} root@${REMOTE_HOST} \
            "docker exec -it ${CONTAINER_NAME} sh"
        ;;
    help)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac 