#!/bin/bash

# Registry URL
REGISTRY="harbor.factory-data-data-444-777.xyz"
IMAGE_NAME="library/node-starter-api"
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}"

# Environment (default to production)
ENV=${1:-prod}

# Update version in package.json
echo "📝 Updating version in package.json..."
node -e "
  const fs = require('fs');
  const pkg = JSON.parse(fs.readFileSync('./package.json'));
  pkg.version = pkg.version.split('.').map((n, i) => i === 2 ? parseInt(n) + 1 : n).join('.');
  fs.writeFileSync('./package.json', JSON.stringify(pkg, null, 2) + '\n');
"

# Get version from package.json
VERSION=$(node -p "require('./package.json').version")

echo "🚀 Starting deployment process for version ${VERSION} in ${ENV} environment"

# Generate SSH key if deploying dev environment
if [ "$ENV" = "dev" ]; then
    echo "🔑 Generating SSH key for development environment..."
    if [ ! -f "./deploy_key" ]; then
        ssh-keygen -t rsa -b 4096 -f ./deploy_key -N ""
        echo "✅ SSH key pair generated"
        echo "⚠️  Important: Add this public key to your authorized sources:"
        cat ./deploy_key.pub
    fi
fi

# Build the Docker image
echo "📦 Building Docker image..."
if [ "$ENV" = "dev" ]; then
    docker build --platform linux/amd64 -t ${FULL_IMAGE_NAME}:dev --target dev -f docker/Dockerfile .
else
    docker build --platform linux/amd64 -t ${FULL_IMAGE_NAME}:${VERSION} --target final -f docker/Dockerfile .
fi

if [ $? -eq 0 ]; then
    echo "✅ Docker build successful"
else
    echo "❌ Docker build failed"
    exit 1
fi

# Push the images
echo "📤 Pushing images to registry..."
if [ "$ENV" = "dev" ]; then
    docker push ${FULL_IMAGE_NAME}:dev
    echo "Pushed ${FULL_IMAGE_NAME}:dev"
else
    docker tag ${FULL_IMAGE_NAME}:${VERSION} ${FULL_IMAGE_NAME}:latest
    docker push ${FULL_IMAGE_NAME}:${VERSION}
    docker push ${FULL_IMAGE_NAME}:latest
    echo "Pushed ${FULL_IMAGE_NAME}:${VERSION} and latest"
fi

if [ $? -eq 0 ]; then
    echo "✅ Successfully deployed version ${VERSION}"
else
    echo "❌ Push failed"
    exit 1
fi 