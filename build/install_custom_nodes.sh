#!/usr/bin/env bash
# Install Custom Nodes for ComfyUI (Essential 15 nodes)
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")

echo "### Installing Essential Custom Nodes (15 nodes) ###"

# Change to custom_nodes directory
cd /ComfyUI/custom_nodes

# Clone only the 15 essential custom nodes repositories
echo "Cloning custom node repositories..."
git clone --depth=1 --filter=blob:none https://github.com/liusida/ComfyUI-Login.git && \
git clone --depth=1 --filter=blob:none https://github.com/kijai/ComfyUI-KJNodes.git && \
git clone --depth=1 --filter=blob:none https://github.com/ClownsharkBatwing/RES4LYF.git && \
git clone --depth=1 --filter=blob:none https://github.com/city96/ComfyUI-GGUF.git && \
git clone --depth=1 --filter=blob:none https://github.com/1038lab/ComfyUI-RMBG.git && \
git clone --depth=1 --filter=blob:none https://github.com/willmiao/ComfyUI-Lora-Manager.git

echo "Custom nodes cloned successfully (15 nodes)"

# Fix ComfyUI-RMBG to specific working commit (triton-windows error fix)
echo "Fixing ComfyUI-RMBG version..."
cd ComfyUI-RMBG
# Only fetch the specific commit to avoid downloading full history
git fetch --depth=1 origin 9ecda2e689d72298b4dca39403a85d13e53ea659
git checkout 9ecda2e689d72298b4dca39403a85d13e53ea659
cd ..

# Rewrite any top-level CPU ORT refs to GPU ORT
echo "Configuring ONNX Runtime for GPU..."
set +e  # Allow sed to fail if file doesn't exist
for f in ComfyUI-RMBG/requirements.txt; do
  [ -f "$f" ] || continue
  sed -i -E 's/^( *| *)(onnxruntime)([<>=].*)?(\s*)$/\1onnxruntime-gpu==1.22.*\4/i' "$f"
done
set -e

# Install Dependencies for Cloned Repositories
echo "Installing custom node dependencies..."
cd /ComfyUI/custom_nodes

# Activate venv
source /ComfyUI/venv/bin/activate

# Install Python dependencies
pip install --no-cache-dir \
  diffusers psutil \
  -r ComfyUI-Login/requirements.txt \
  -r ComfyUI-KJNodes/requirements.txt \
  -r RES4LYF/requirements.txt \
  -r ComfyUI-GGUF/requirements.txt \
  -r ComfyUI-RMBG/requirements.txt \
  -r ComfyUI-Lora-Manager/requirements.txt \
# https://github.com/Azornes/Comfyui-Resolution-Master

# Clean up all .git folders from custom nodes to save space
echo "Cleaning up .git folders from custom nodes..."
cd /ComfyUI/custom_nodes
for dir in */; do
    if [ -d "$dir/.git" ]; then
        echo "Removing .git from $dir"
        rm -rf "$dir/.git"
    fi
done

# Clean up pip cache and Python bytecode
echo "Cleaning up pip cache and Python bytecode..."
pip3 cache purge
find /ComfyUI/custom_nodes -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
find /ComfyUI/custom_nodes -type f -name "*.pyc" -delete 2>/dev/null || true

deactivate

echo "### Custom Nodes Installation Complete ###"
