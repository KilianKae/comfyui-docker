#!/usr/bin/env bash
# Model Downloader Script for ComfyUI Production
# This script contains functions to download models from Hugging Face, CivitAI, and direct URLs

set -euo pipefail

# Function to download models from Hugging Face (categorized)
download_model_HF() {
    local model_var="$1"
    local file_var="$2"
    local dest_dir="$3"

    if [[ -n "${!model_var:-}" && -n "${!file_var:-}" ]]; then
        local target="/workspace/ComfyUI/models/$dest_dir"
        mkdir -p "$target"
        echo "ℹ️ [DOWNLOAD] Fetching ${!model_var}/${!file_var} → $target"
        hf download "${!model_var}" "${!file_var}" --local-dir "$target" || \
            echo "⚠️ Failed to download ${!model_var}/${!file_var}"
        sleep 1
    fi

    return 0
}

# Function to download models or files from Hugging Face (generic)
download_generic_HF() {
    local model_var="$1"
    local file_var="$2"
    local dest_dir="$3"

    local model="${!model_var:-}"
    [[ -z "$model" ]] && return 0

    local file=""
    if [[ -n "$file_var" ]]; then
        file="${!file_var:-}"
    fi

    local target="/workspace/ComfyUI/$dest_dir"
    mkdir -p "$target"

    if [[ -n "$file" ]]; then
        echo "ℹ️ [DOWNLOAD] Fetching $model/$file → $target"
        hf download "$model" "$file" --local-dir "$target" || \
            echo "⚠️ Failed to download $model/$file"
    else
        echo "ℹ️ [DOWNLOAD] Fetching $model → $target"
        hf download "$model" --local-dir "$target" || \
            echo "⚠️ Failed to download $model"
    fi

    sleep 1
    return 0
}

# Function to download models from CivitAI
download_model_CIVITAI() {
    local url_var="$1"
    local dest_dir="$2"

    if [[ -z "${!url_var:-}" ]]; then
        return 0
    fi

    if [[ -z "${CIVITAI_TOKEN:-}" ]]; then
        echo "⚠️ ERROR: CIVITAI_TOKEN is not set as an environment variable '$url_var' not downloaded"
        return 1
    fi

    local target="/workspace/ComfyUI/models/$dest_dir"
    mkdir -p "$target"

    local url="${!url_var}"

    # Convert model page URL to API download URL if needed
    if [[ "$url" == *"modelVersionId="* ]]; then
        local version_id
        version_id=$(echo "$url" | grep -oP 'modelVersionId=\K[0-9]+')
        url="https://civitai.com/api/download/models/${version_id}"
    elif [[ "$url" == *"/models/"* && "$url" != *"/api/"* ]]; then
        echo "⚠️ [$url_var] Missing modelVersionId in URL, skipping"
        return 0
    fi

    echo "ℹ️ [DOWNLOAD] Fetching $url → $target ..."
    # civitai-downloader expects CIVITAI_API_TOKEN env var
    CIVITAI_API_TOKEN="${CIVITAI_TOKEN}" download-model "$url" "$target" || \
        echo "⚠️ Failed to download $url"
    sleep 1
    return 0
}

# Function to download workflow files
download_workflow() {
    local url_var="$1"

    # Check if URL variable is set and not empty
    if [[ -z "${!url_var:-}" ]]; then
        return 0
    fi

    # Destination directory
    local dest_dir="/workspace/ComfyUI/user/default/workflows/"
    mkdir -p "$dest_dir"

    # Get filename from URL
    local url="${!url_var}"
    local filename
    filename=$(basename "$url")
    local filepath="${dest_dir}${filename}"

    # Skip entire process if file already exists
    if [[ -f "$filepath" ]]; then
        echo "⏭️  [SKIP] $filename already exists — skipping download and extraction"
        return 0
    fi

    # Download file
    echo "ℹ️ [DOWNLOAD] Fetching $filename ..."
    if wget -q -P "$dest_dir" "$url"; then
        echo "[DONE] Downloaded $filename"
    else
        echo "⚠️  Failed to download $url"
        return 0
    fi

    # Automatically extract common archive formats
    case "$filename" in
        *.zip)
            echo "📦  [EXTRACT] Unzipping $filename ..."
            if unzip -o "$filepath" -d "$dest_dir" >/dev/null 2>&1; then
                echo "[DONE] Extracted $filename"
            else
                echo "⚠️  Failed to unzip $filename"
            fi
            ;;
        *.tar.gz|*.tgz)
            echo "📦  [EXTRACT] Extracting $filename (tar.gz) ..."
            if tar -xzf "$filepath" -C "$dest_dir"; then
                echo "[DONE] Extracted $filename"
            else
                echo "⚠️  Failed to extract $filename"
            fi
            ;;
        *.tar.xz)
            echo "📦  [EXTRACT] Extracting $filename (tar.xz) ..."
            if tar -xJf "$filepath" -C "$dest_dir"; then
                echo "[DONE] Extracted $filename"
            else
                echo "⚠️  Failed to extract $filename"
            fi
            ;;
        *.tar.bz2)
            echo "📦  [EXTRACT] Extracting $filename (tar.bz2) ..."
            if tar -xjf "$filepath" -C "$dest_dir"; then
                echo "[DONE] Extracted $filename"
            else
                echo "⚠️  Failed to extract $filename"
            fi
            ;;
        *.7z)
            echo "📦  [EXTRACT] Extracting $filename (7z) ..."
            if 7z x -y -o"$dest_dir" "$filepath" >/dev/null 2>&1; then
                echo "[DONE] Extracted $filename"
            else
                echo "⚠️  Failed to extract $filename"
            fi
            ;;
        *)
            echo "[INFO] No extraction needed for $filename"
            ;;
    esac

    sleep 1
    return 0
}

# Main provisioning function
run_model_provisioning() {
    echo "=== Starting Model Provisioning ==="

    # Provisioning workflows
    echo "📥 Provisioning workflows"

    for i in $(seq 1 50); do
        VAR="WORKFLOW${i}"
        download_workflow "$VAR"
    done

    # Provisioning Models from Hugging Face
    echo "📥 Provisioning models from Hugging Face"

    # Categories: NAME:SUFFIX:MAP
    CATEGORIES_HF=(
      "VAE:VAE_FILENAME:vae"
      "UPSCALER:UPSCALER_PTH:upscale_models"
      "LORA:LORA_FILENAME:loras"
      "TEXT_ENCODERS:TEXT_ENCODERS_FILENAME:text_encoders"
      "CLIP_VISION:CLIP_VISION_FILENAME:clip_vision"
      "PATCHES:PATCHES_FILENAME:model_patches"
      "AUDIO_ENCODERS:AUDIO_ENCODERS_FILENAME:audio_encoders"
      "DIFFUSION_MODELS:DIFFUSION_MODELS_FILENAME:diffusion_models"
      "CHECKPOINTS:CHECKPOINTS_FILENAME:checkpoints"
      "VL:VL_FILENAME:VLM"
      "SAMS:SAMS_FILENAME:sams"
      "LATENT_UPSCALE:LATENT_UPSCALE_FILENAME:latent_upscale_models"
    )

    for cat in "${CATEGORIES_HF[@]}"; do
      IFS=":" read -r NAME SUFFIX DIR <<< "$cat"

      for i in $(seq 1 20); do
        VAR1="HF_MODEL_${NAME}${i}"
        VAR2="HF_MODEL_${SUFFIX}${i}"
        download_model_HF "$VAR1" "$VAR2" "$DIR"
      done
    done

    # Huggingface download file to specified directory
    echo "📥 Provisioning generic Hugging Face models/files"
    for i in $(seq 1 20); do
        VAR1="HF_MODEL${i}"
        VAR2="HF_MODEL_FILENAME${i}"
        DIR_VAR="HF_MODEL_DIR${i}"
        download_generic_HF "${VAR1}" "${VAR2}" "${!DIR_VAR:-}"
    done

    # Huggingface download full model to specified directory
    for i in $(seq 1 20); do
        VAR1="HF_FULL_MODEL${i}"
        DIR_VAR="HF_MODEL_DIR${i}"
        download_generic_HF "${VAR1}" "" "${!DIR_VAR:-}"
    done

    # Provisioning Models from CivitAI
    echo "📥 Provisioning models from CivitAI"

    # Categories: NAME:MAP
    CATEGORIES_CIVITAI=(
       "LORA_URL:loras"
    )

    for cat in "${CATEGORIES_CIVITAI[@]}"; do
      IFS=":" read -r NAME DIR <<< "$cat"

      for i in $(seq 1 50); do
        VAR1="CIVITAI_MODEL_${NAME}${i}"
        download_model_CIVITAI "$VAR1" "$DIR"
      done
    done

    echo "=== Model Provisioning Complete ==="
}

# Export functions for use in other scripts
export -f download_model_HF
export -f download_generic_HF
export -f download_model_CIVITAI
export -f download_workflow
export -f run_model_provisioning
