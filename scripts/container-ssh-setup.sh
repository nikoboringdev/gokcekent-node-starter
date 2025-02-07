#!/bin/bash
set -e

# Create SSH directory and set permissions
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Start SSH daemon
/usr/sbin/sshd

# Keep container running
exec "$@" 