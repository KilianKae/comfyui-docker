#!/usr/bin/env bash
# ComfyUI Production Startup Script
# Combines RunPod optimization, persistent storage sync, and automated model provisioning

set -euo pipefail

echo "=========================================="
echo "  ComfyUI Production Container Starting (1.0.5)"
echo "=========================================="
echo ""
echo "⏳ Please wait until you see the message:"
echo "   🎉 Provisioning complete, ready to create AI content! 🎉"
echo ""

# ============================================
# Phase 1: SSH Setup
# ============================================
if [[ -n "${PUBLIC_KEY:-}" ]]; then
    echo "🔑 Configuring SSH access..."
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    service ssh start
    echo "✅ SSH enabled"
fi

# ============================================
# Phase 2: Environment Export (RunPod)
# ============================================
if [[ -n "${RUNPOD_GPU_COUNT:-}" ]]; then
   echo "ℹ️  Exporting RunPod environment variables..."
   printenv | grep -E '^RUNPOD_|^PATH=|^_=' \
     | awk -F = '{ print "export " $1 "=\"" $2 "\"" }' >> /etc/rp_environment
   echo 'source /etc/rp_environment' >> ~/.bashrc
fi

# ============================================
# Phase 3: Workspace Initialization
# ============================================
echo "ℹ️  Initializing workspace..."
mkdir -p /workspace/output/
mkdir -p /workspace/logs/

# Set PyTorch optimizations
export PYTORCH_ALLOC_CONF=expandable_segments:True,garbage_collection_threshold:0.8
export COMFYUI_VRAM_MODE=HIGH_VRAM

# ============================================
# Phase 4: GPU Detection
# ============================================
echo "🔍 Detecting GPU and CUDA..."

HAS_GPU=0
if command -v nvidia-smi >/dev/null 2>&1; then
  if nvidia-smi >/dev/null 2>&1; then
    HAS_GPU=1
    GPU_MODEL=$(nvidia-smi --query-gpu=name --format=csv,noheader | xargs | sed 's/,/, /g')
    echo "✅ GPU detected via nvidia-smi → ${GPU_MODEL}"
  else
    echo "⚠️  nvidia-smi found but failed to run"
  fi
else
  echo "⚠️  No GPU detected via nvidia-smi"
fi

# Check CUDA availability via PyTorch
HAS_CUDA=0
if command -v python >/dev/null 2>&1; then
  if python - << 'PY' >/dev/null 2>&1
import sys
try:
    import torch
    sys.exit(0 if torch.cuda.is_available() else 1)
except Exception:
    sys.exit(1)
PY
  then
    HAS_CUDA=1
    echo "✅ CUDA available via PyTorch"
  else
    echo "⚠️  CUDA not available in PyTorch"
  fi
else
  echo "⚠️  Python not found"
fi

# ============================================
# Phase 5: Pre-Start Sync & Service Launch
# ============================================
echo ""
echo "🔄 Running pre-start synchronization..."
/pre_start.sh

# ============================================
# Phase 6: Wait for ComfyUI to Come Online
# ============================================
echo ""
echo "⏳ Waiting for ComfyUI to come online..."
echo "   (Logs available at: /workspace/logs/comfyui.log)"
echo ""

HAS_COMFYUI=0
COUNT=0
COMFYUI_LOG="/workspace/logs/comfyui.log"

# Wait if GPU is detected (CUDA check happens pre-sync, so use HAS_GPU instead)
if [[ "$HAS_GPU" -eq 1 ]]; then
    # Start background log tail if log file exists or appears
    (
        while [[ ! -f "$COMFYUI_LOG" ]]; do sleep 1; done
        tail -f "$COMFYUI_LOG" 2>/dev/null | sed 's/^/   [ComfyUI] /'
    ) &
    LOG_TAIL_PID=$!

    # Wait indefinitely for ComfyUI to come online
    until curl -s http://127.0.0.1:3001 > /dev/null 2>&1; do
        COUNT=$((COUNT+1))
        echo "   Waiting for ComfyUI... (attempt $COUNT, elapsed: $((COUNT*5))s)"
        sleep 5
    done

    # Stop the log tail
    kill $LOG_TAIL_PID 2>/dev/null || true

    HAS_COMFYUI=1
    echo ""
    echo "✅ ComfyUI is online! (after $((COUNT*5)) seconds)"
else
    echo "⚠️  No GPU detected, ComfyUI may not have started"
fi

# ============================================
# Phase 7: Model Provisioning
# ============================================
if [[ "$HAS_COMFYUI" -eq 1 ]]; then
    echo ""
    echo "📦 Starting automated model provisioning..."
    echo "   This may take several minutes depending on model sizes"
    echo ""

    # Inject CIVITAI_TOKEN into Lora Manager if available
    if [[ -n "${CIVITAI_TOKEN:-}" ]]; then
        SETTINGS_DIR="/workspace/ComfyUI/custom_nodes/ComfyUI-Lora-Manager"
        SETTINGS_FILE="$SETTINGS_DIR/settings.json"
        TEMPLATE_FILE="$SETTINGS_DIR/settings.json.template"

        if [[ -f "$TEMPLATE_FILE" ]]; then
            mkdir -p "$SETTINGS_DIR"
            echo "ℹ️  Injecting CIVITAI_TOKEN into ComfyUI-Lora-Manager"
            jq --arg token "$CIVITAI_TOKEN" \
               '.civitai_api_key = $token' \
               "$TEMPLATE_FILE" > "$SETTINGS_FILE" || true
        fi
    fi

    # Activate venv for huggingface-cli access
    source /workspace/ComfyUI/venv/bin/activate

    # Source model downloader functions
    source /model_downloader.sh

    # Run provisioning
    run_model_provisioning

    # Deactivate venv
    deactivate

    echo ""
    echo "✅ Model provisioning complete!"
else
    echo ""
    echo "⚠️  Skipping model provisioning (ComfyUI not online)"
fi

# ============================================
# Phase 8: Display Service Information
# ============================================
echo ""
echo "=========================================="
echo "  🎉 Container Ready!"
echo "=========================================="
echo ""
echo "📊 Service Status:"
echo "   - ComfyUI:      $([ "$HAS_COMFYUI" -eq 1 ] && echo "✅ Running" || echo "❌ Not Running")"
echo "   - App Manager:  ✅ Running"
echo "   - GPU:          $([ "$HAS_GPU" -eq 1 ] && echo "✅ Detected" || echo "❌ Not Detected")"
echo "   - CUDA:         $([ "$HAS_GPU" -eq 1 ] && echo "✅ Available" || echo "❌ Not Available")"
echo ""
echo "🌐 Access URLs:"
echo "   - ComfyUI:      http://localhost:3000"
echo "   - App Manager:  http://localhost:8000"
if [[ -n "${RUNPOD_POD_ID:-}" ]]; then
    echo "   - RunPod URL:   https://${RUNPOD_POD_ID}-3000.proxy.runpod.net"
fi
echo ""
echo "📁 Important Paths:"
echo "   - ComfyUI:      /workspace/ComfyUI"
echo "   - Models:       /workspace/ComfyUI/models/"
echo "   - Workflows:    /workspace/ComfyUI/user/default/workflows/"
echo "   - Output:       /workspace/output/"
echo "   - Logs:         /workspace/logs/"
echo ""
echo "🔧 Environment Variables:"
echo "   - TEMPLATE_VERSION:  ${TEMPLATE_VERSION:-not set}"
echo "   - VENV_PATH:         ${VENV_PATH:-not set}"
if [[ -n "${CIVITAI_TOKEN:-}" ]]; then
    echo "   - CIVITAI_TOKEN:     ✅ Set"
else
    echo "   - CIVITAI_TOKEN:     ⚠️  Not set (CivitAI downloads disabled)"
fi
echo ""
echo "=========================================="
echo "🎨 Ready to create AI content!"
echo "=========================================="
echo ""

# Keep container running
sleep infinity
