ARG NODE_VERSION=20.18.0

# Build stage
FROM node:${NODE_VERSION}-alpine as build

WORKDIR /usr/src/app

# Copy all source files
COPY . .
ADD env.txt ./.env

# Install dependencies and build
RUN npm ci

# Production stage
FROM node:${NODE_VERSION}-alpine as final

WORKDIR /usr/src/app

# Create non-root user permissions
RUN chown -R node:node /usr/src/app

# Install necessary packages
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    curl \
    busybox-extras \
    shadow \
    haproxy \
    supervisor \
    git

# Setup supervisor
RUN mkdir /etc/supervisor.d/
COPY docker/supervisor/supervisor.conf /etc/supervisor.d/supervisor.ini
COPY docker/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg

# Copy application files
COPY --chown=1000:1000 package.json .
COPY --chown=1000:1000 package-lock.json .
ADD --chown=1000:1000 env.txt ./.env
COPY --chown=1000:1000 --from=build /usr/src/app/node_modules ./node_modules
COPY --chown=1000:1000 --from=build /usr/src/app/dist ./dist

# Set environment variables
ENV TZ="UTC"
ENV NODE_ENV="production"

# Start supervisor
CMD npx nodemon --watch /usr/src/app/dist --ext js --exec "NODE_ENV=production node dist/server.js"

# # Health check
HEALTHCHECK --start-period=20s --interval=10s --timeout=5s --retries=3 \
    CMD curl -f http://127.0.0.1:3500/api/health || exit 1

# Expose application port
EXPOSE 3500
