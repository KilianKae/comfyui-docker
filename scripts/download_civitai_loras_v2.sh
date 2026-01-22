TARGET_DIR="/workspace/ComfyUI/models/loras"
mkdir -p "$TARGET_DIR"

for i in $(seq 1 50); do
    VAR="CIVITAI_MODEL_LORA_URL${i}"
    URL="${!VAR:-}"
    if [[ -n "$URL" ]]; then
        # Convert model page URL to API download URL
        if [[ "$URL" == *"modelVersionId="* ]]; then
            VERSION_ID=$(echo "$URL" | grep -oP 'modelVersionId=\K[0-9]+')
            URL="https://civitai.com/api/download/models/${VERSION_ID}"
        elif [[ "$URL" == *"/models/"* && "$URL" != *"/api/"* ]]; then
            # URL like /models/123456/slug - extract model ID and fetch latest version
            MODEL_ID=$(echo "$URL" | grep -oP '/models/\K[0-9]+')
            if [[ -n "$MODEL_ID" ]]; then
                echo "Fetching version info for model $MODEL_ID..."
                VERSION_ID=$(curl -s "https://civitai.com/api/v1/models/${MODEL_ID}" \
                    -H "Authorization: Bearer ${CIVITAI_API_TOKEN:-}" | \
                    grep -oP '"modelVersions":\[\{"id":\K[0-9]+' | head -1)
                if [[ -n "$VERSION_ID" ]]; then
                    URL="https://civitai.com/api/download/models/${VERSION_ID}"
                else
                    echo "[$i] Could not fetch version ID for model $MODEL_ID, skipping"
                    continue
                fi
            else
                echo "[$i] Could not extract model ID from URL, skipping"
                continue
            fi
        fi
        echo "Downloading [$i]: $URL"
        download-model "$URL" "$TARGET_DIR" || echo "Failed: $URL"
    fi
done

echo "Done!"
