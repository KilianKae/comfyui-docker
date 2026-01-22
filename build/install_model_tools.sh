#!/usr/bin/env bash
# Install Model Download Tools for ComfyUI
set -euo pipefail

echo "### Installing Model Download Tools ###"

# Activate venv
source /ComfyUI/venv/bin/activate

# Install Hugging Face CLI
echo "Installing Hugging Face Hub CLI..."
pip install --no-cache-dir huggingface-hub[cli,hf_transfer]

# Install additional utilities if not present
echo "Checking for wget, curl, jq..."
apk add --no-cache wget curl jq || apt-get update && apt-get install -y wget curl jq || true

echo "### Model Download Tools Installation Complete ###"
echo "Installed tools:"
echo "  - hf (Hugging Face CLI, in venv)"
echo "  - wget (HTTP download)"
echo "  - curl (HTTP client)"
echo "  - jq (JSON processor)"
echo "  - download-model (CivitAI downloader, pre-installed)"
