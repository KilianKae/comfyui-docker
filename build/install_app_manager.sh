#!/usr/bin/env bash
set -e

git clone https://github.com/ashleykleynhans/app-manager.git /app-manager
cd /app-manager
git checkout tags/${APP_MANAGER_VERSION}

# Remove .git folder to save space
rm -rf .git

npm install

# Clean up npm cache
npm cache clean --force
