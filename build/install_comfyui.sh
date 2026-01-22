#!/usr/bin/env bash
set -e

# Clone the repo
git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI
cd /ComfyUI
git checkout ${COMFYUI_VERSION}

# Remove .git folder to save space
rm -rf .git

# Create and activate the venv
python3 -m venv --system-site-packages venv
source venv/bin/activate

# Upgrade pip
pip3 install --no-cache-dir --upgrade pip

# Install torch, xformers and sageattention
pip3 install --no-cache-dir torch=="${TORCH_VERSION}" torchvision torchaudio --index-url ${INDEX_URL}
pip3 install --no-cache-dir xformers=="${XFORMERS_VERSION}" --index-url ${INDEX_URL}

# Install requirements
pip3 install --no-cache-dir -r requirements.txt
pip3 install --no-cache-dir accelerate
pip3 install --no-cache-dir sageattention==1.0.6
pip3 install --no-cache-dir setuptools --upgrade

# Install ComfyUI Custom Nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
cd custom_nodes/ComfyUI-Manager
rm -rf .git
pip3 install --no-cache-dir -r requirements.txt

# Fix some incorrect modules
pip3 install --no-cache-dir numpy==1.26.4

# Clean up pip cache and Python bytecode
pip3 cache purge
find /ComfyUI -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
find /ComfyUI -type f -name "*.pyc" -delete 2>/dev/null || true

deactivate
