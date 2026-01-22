#!/usr/bin/env bash

ARGS=("$@" --listen 0.0.0.0 --port 3001)

export PYTHONUNBUFFERED=1
echo "Starting ComfyUI"
cd /workspace/ComfyUI
source venv/bin/activate

# Detect CUDA version and disable xformers for CUDA 12.8+ (pre-built wheels have Hopper-specific code)
CUDA_VERSION=$(python3 -c "import torch; print(torch.version.cuda or '')" 2>/dev/null)
if [[ -n "$CUDA_VERSION" ]]; then
    CUDA_MAJOR=$(echo "$CUDA_VERSION" | cut -d. -f1)
    CUDA_MINOR=$(echo "$CUDA_VERSION" | cut -d. -f2)
    if [[ "$CUDA_MAJOR" -ge 12 && "$CUDA_MINOR" -ge 8 ]]; then
        echo "CUDA ${CUDA_VERSION} detected - disabling xformers (using PyTorch native SDPA)"
        ARGS+=(--disable-xformers)
    fi
fi

TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"
python3 main.py "${ARGS[@]}" > /workspace/logs/comfyui.log 2>&1 &
echo "ComfyUI started"
echo "Log file: /workspace/logs/comfyui.log"
deactivate
