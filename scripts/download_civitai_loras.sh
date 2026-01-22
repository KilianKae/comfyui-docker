#!/usr/bin/env bash
# Manual CivitAI LoRA downloader - run via SSH
# Usage: ./download_civitai_loras.sh

set -euo pipefail

# Check if CIVITAI_TOKEN is set
if [[ -z "${CIVITAI_TOKEN:-}" ]]; then
    echo "❌ ERROR: CIVITAI_TOKEN environment variable is not set"
    echo "   Set it with: export CIVITAI_TOKEN=your_token_here"
    exit 1
fi

echo "✅ CIVITAI_TOKEN is set"

# Target directory for LoRAs
TARGET_DIR="/workspace/ComfyUI/models/loras"
mkdir -p "$TARGET_DIR"

echo "📁 Downloading LoRAs to: $TARGET_DIR"
echo ""

# Find all CIVITAI_MODEL_LORA_URL* environment variables and download
downloaded=0
for i in $(seq 1 50); do
    VAR="CIVITAI_MODEL_LORA_URL${i}"
    URL="${!VAR:-}"

    if [[ -n "$URL" ]]; then
        echo "ℹ️  [${i}] Downloading: $URL"
        if download-model "$URL" "$TARGET_DIR"; then
            echo "✅ [${i}] Success"
            ((downloaded++))
        else
            echo "⚠️  [${i}] Failed to download"
        fi
        echo ""
    fi
done

if [[ $downloaded -eq 0 ]]; then
    echo "⚠️  No CIVITAI_MODEL_LORA_URL* environment variables found"
    echo ""
    echo "Set them like this:"
    echo "  export CIVITAI_MODEL_LORA_URL1=https://civitai.com/api/download/models/123456"
    echo "  export CIVITAI_MODEL_LORA_URL2=https://civitai.com/api/download/models/789012"
else
    echo "✅ Downloaded $downloaded LoRA(s)"
fi
