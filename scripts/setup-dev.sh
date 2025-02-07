#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REMOTE_HOST=${REMOTE_HOST:-"your-remote-host"}
REMOTE_SSH_PORT=${REMOTE_SSH_PORT:-"2222"}
CONTAINER_NAME="node-dev"

echo -e "${BLUE}🚀 Setting up development environment...${NC}"

# Generate SSH key if it doesn't exist
if [ ! -f "./deploy_key" ]; then
    ssh-keygen -t rsa -b 4096 -f ./deploy_key -N ""
    chmod 600 deploy_key
fi

# Create Docker context for remote host
echo -e "${BLUE}📦 Setting up Docker context...${NC}"
docker context create remote-dev \
    --docker "host=ssh://root@${REMOTE_HOST}:${REMOTE_SSH_PORT}" \
    --default-stack-orchestrator=swarm

# Switch to remote context
docker context use remote-dev

# Create development container
echo -e "${BLUE}🛠 Creating development container...${NC}"
docker build --target dev -t node-dev:local .
docker run -d \
    --name ${CONTAINER_NAME} \
    -p 3000:3000 \
    -p 9229:9229 \
    -p 2222:22 \
    -v "$(pwd):/home/developer/app" \
    node-dev:local

# Generate VS Code configuration
mkdir -p .vscode
cat > .vscode/settings.json << EOF
{
    "remote.SSH.defaultExtensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
    ],
    "remote.SSH.path": "/usr/bin/ssh",
    "remote.SSH.useFlock": false,
    "files.watcherExclude": {
        "**/node_modules/**": true,
        "**/dist/**": true
    }
}
EOF

cat > .vscode/launch.json << EOF
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "node",
            "request": "attach",
            "name": "Attach to Remote",
            "address": "localhost",
            "port": 9229,
            "localRoot": "\${workspaceFolder}",
            "remoteRoot": "/home/developer/app"
        }
    ]
}
EOF

echo -e "${GREEN}✅ Development environment setup complete${NC}"
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Add this public key to your remote host:"
cat deploy_key.pub
echo -e "\n2. Open VS Code and install 'Remote - SSH' extension"
echo "3. Connect to remote host using VS Code command palette: 'Remote-SSH: Connect to Host'" 