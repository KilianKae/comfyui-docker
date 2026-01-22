# ComfyUI Production Docker

A production-grade Docker setup for ComfyUI with automated model downloading, 50+ pre-installed custom nodes, and optimized for RunPod cloud deployment.

## Features

- **Multi-Variant Builds**: Support for CUDA 12.4/12.8 with Python 3.11/3.12
- **50+ Custom Nodes**: Pre-installed custom nodes including Login, KJNodes, RMBG, SAM2, JoyCaption, and more
- **Automated Model Downloading**: Runtime model provisioning from Hugging Face, CivitAI, and direct URLs
- **Production Ready**: NGINX reverse proxy, App Manager, persistent storage sync
- **RunPod Optimized**: Intelligent syncing for RunPod network volumes
- **Flexible Configuration**: Environment variable-based model provisioning

## Quick Start

### Building the Image

```bash
# Build default variant (CUDA 12.8, Python 3.12 - RTX 5090)
docker buildx bake

# Build specific variant (CUDA 12.4, Python 3.11 - RTX 4090, A6000)
docker buildx bake cu124-py311

# Build all variants
docker buildx bake all
```

### Running the Container

#### Basic Usage

```bash
docker run -it --gpus all \
  -p 3000:3000 \
  -p 8000:8000 \
  -v $(pwd)/workspace:/workspace \
  kiliankaslin/comfyui-production:cu128-py312-v1.0.0
```

#### With Model Provisioning

```bash
docker run -it --gpus all \
  -p 3000:3000 \
  -p 8000:8000 \
  -v $(pwd)/workspace:/workspace \
  -e HF_MODEL_DIFFUSION_MODELS1=Comfy-Org/flux1-dev \
  -e HF_MODEL_DIFFUSION_MODELS_FILENAME1=flux1-dev.safetensors \
  -e HF_MODEL_TEXT_ENCODERS1=comfyanonymous/flux_text_encoders \
  -e HF_MODEL_TEXT_ENCODERS_FILENAME1=t5xxl_fp16.safetensors \
  -e CIVITAI_TOKEN=your_civitai_api_token \
  -e CIVITAI_MODEL_LORA_URL1=https://civitai.com/api/download/models/123456 \
  kiliankaslin/comfyui-production:cu128-py312-v1.0.0
```

## Environment Variables

### Service Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `DISABLE_AUTOLAUNCH` | Skip auto-starting ComfyUI | Not set (auto-launch enabled) |
| `DISABLE_SYNC` | Skip syncing to persistent storage | Not set (sync enabled) |
| `EXTRA_ARGS` | Additional ComfyUI arguments | Not set |
| `PUBLIC_KEY` | SSH public key for remote access | Not set |

### Model Provisioning

#### Workflow Downloads

```bash
WORKFLOW1=https://example.com/workflow.json
WORKFLOW2=https://example.com/my-workflow.zip
# ... up to WORKFLOW50
```

Supports: `.json`, `.zip`, `.tar.gz`, `.tar.xz`, `.tar.bz2`, `.7z`

#### Hugging Face Models (Categorized)

Download models to specific ComfyUI model directories:

```bash
# VAE models
HF_MODEL_VAE1=stabilityai/sdxl-vae
HF_MODEL_VAE_FILENAME1=sdxl_vae.safetensors

# LoRA models
HF_MODEL_LORA1=your-repo/your-lora
HF_MODEL_LORA_FILENAME1=lora.safetensors

# Diffusion models
HF_MODEL_DIFFUSION_MODELS1=Comfy-Org/flux1-dev
HF_MODEL_DIFFUSION_MODELS_FILENAME1=flux1-dev.safetensors

# Text encoders
HF_MODEL_TEXT_ENCODERS1=comfyanonymous/flux_text_encoders
HF_MODEL_TEXT_ENCODERS_FILENAME1=t5xxl_fp16.safetensors

# Upscale models
HF_MODEL_UPSCALER1=your-repo/upscaler
HF_MODEL_UPSCALER_PTH1=model.pth

# CLIP Vision
HF_MODEL_CLIP_VISION1=your-repo/clip
HF_MODEL_CLIP_VISION_FILENAME1=clip.safetensors

# Model Patches
HF_MODEL_PATCHES1=your-repo/patch
HF_MODEL_PATCHES_FILENAME1=patch.safetensors

# Audio Encoders
HF_MODEL_AUDIO_ENCODERS1=your-repo/audio
HF_MODEL_AUDIO_ENCODERS_FILENAME1=audio.safetensors

# Checkpoints
HF_MODEL_CHECKPOINTS1=your-repo/checkpoint
HF_MODEL_CHECKPOINTS_FILENAME1=checkpoint.safetensors

# VLM (Vision-Language Models)
HF_MODEL_VL1=your-repo/vlm
HF_MODEL_VL_FILENAME1=vlm.safetensors

# SAM models
HF_MODEL_SAMS1=your-repo/sam
HF_MODEL_SAMS_FILENAME1=sam.safetensors

# Latent Upscale
HF_MODEL_LATENT_UPSCALE1=your-repo/latent
HF_MODEL_LATENT_UPSCALE_FILENAME1=latent.safetensors
```

Each category supports up to 20 indexed downloads (e.g., `HF_MODEL_VAE1` through `HF_MODEL_VAE20`)

#### Generic Hugging Face Downloads

For custom paths:

```bash
# Download single file
HF_MODEL1=repo/model-name
HF_MODEL_FILENAME1=specific_file.safetensors
HF_MODEL_DIR1=models/custom_path

# Download full model
HF_FULL_MODEL1=repo/full-model
HF_MODEL_DIR1=models/another_path

# ... up to HF_MODEL20 / HF_FULL_MODEL20
```

#### CivitAI Downloads

```bash
CIVITAI_TOKEN=your_civitai_api_token
CIVITAI_MODEL_LORA_URL1=https://civitai.com/api/download/models/123456
CIVITAI_MODEL_LORA_URL2=https://civitai.com/api/download/models/789012
# ... up to CIVITAI_MODEL_LORA_URL50
```

**Note:** `CIVITAI_TOKEN` is required for CivitAI downloads.

## Directory Structure

```
/workspace/ComfyUI/
├── models/
│   ├── vae/                      # VAE models
│   ├── upscale_models/           # Upscaler models
│   ├── loras/                    # LoRA fine-tuning models
│   ├── text_encoders/            # CLIP/Text encoders
│   ├── clip_vision/              # CLIP vision models
│   ├── model_patches/            # Model patches
│   ├── audio_encoders/           # Audio encoders
│   ├── diffusion_models/         # Main diffusion models
│   ├── checkpoints/              # Model checkpoints
│   ├── VLM/                      # Vision-Language Models
│   ├── sams/                     # SAM models
│   └── latent_upscale_models/    # Latent upscaling models
├── user/default/workflows/       # Workflow files
└── custom_nodes/                 # Custom nodes (50+ pre-installed)
```

## Pre-installed Custom Nodes

This image includes 50+ custom nodes:

- **rgthree-comfy**: Enhanced UI and utilities
- **ComfyUI-Login**: Authentication and user management
- **ComfyUI-KJNodes**: Extended node collection
- **ComfyUI-RMBG**: Background removal
- **ComfyUI-segment-anything-2**: SAM2 integration
- **ComfyUI-JoyCaption**: Image captioning
- **ComfyUI_UltimateSDUpscale**: Advanced upscaling
- **ComfyUI-VideoHelperSuite**: Video processing
- **ComfyUI-Impact-Pack**: Quality improvements
- **ComfyUI-GGUF**: GGUF model support
- **comfyui_controlnet_aux**: ControlNet preprocessing
- **ComfyUI-Lora-Manager**: LoRA management
- And 40+ more for various AI tasks

## Service Ports

| Service | Port | Description |
|---------|------|-------------|
| ComfyUI | 3000 | Main ComfyUI interface (proxied via NGINX) |
| App Manager | 8000 | Application management dashboard |

Internal ports (not exposed by default):
- ComfyUI internal: 3001
- Jupyter Lab: 8888
- Code Server: 7777

## Building Custom Variants

Modify `docker-bake.hcl` to customize builds:

```hcl
variable "RELEASE" {
    default = "v1.0.0"  # Your version
}

variable "REGISTRY_USER" {
    default = "kiliankaslin"  # Your Docker Hub username
}
```

## Advanced Configuration

### Custom ComfyUI Arguments

```bash
docker run ... \
  -e EXTRA_ARGS="--lowvram --disable-xformers" \
  kiliankaslin/comfyui-production:tag
```

### SSH Access

```bash
docker run ... \
  -p 22:22 \
  -e PUBLIC_KEY="ssh-rsa AAAA..." \
  kiliankaslin/comfyui-production:tag
```

### Disable Persistent Storage Sync

```bash
docker run ... \
  -e DISABLE_SYNC=true \
  kiliankaslin/comfyui-production:tag
```

## Example: Full FLUX Model Setup

```bash
docker run -it --gpus all \
  -p 3000:3000 \
  -p 8000:8000 \
  -v $(pwd)/workspace:/workspace \
  -e HF_MODEL_DIFFUSION_MODELS1=Comfy-Org/flux1-dev \
  -e HF_MODEL_DIFFUSION_MODELS_FILENAME1=flux1-dev.safetensors \
  -e HF_MODEL_TEXT_ENCODERS1=comfyanonymous/flux_text_encoders \
  -e HF_MODEL_TEXT_ENCODERS_FILENAME1=t5xxl_fp16.safetensors \
  -e HF_MODEL_TEXT_ENCODERS2=comfyanonymous/flux_text_encoders \
  -e HF_MODEL_TEXT_ENCODERS_FILENAME2=clip_l.safetensors \
  -e HF_MODEL_VAE1=black-forest-labs/FLUX.1-schnell \
  -e HF_MODEL_VAE_FILENAME1=ae.safetensors \
  -e WORKFLOW1=https://your-server.com/flux-workflow.json \
  kiliankaslin/comfyui-production:cu128-py312-v1.0.0
```

## Troubleshooting

### Models Not Downloading

1. Check container logs: `docker logs <container-id>`
2. Verify ComfyUI is online (wait 2-3 minutes after container start)
3. Check environment variables are correctly set
4. For CivitAI: Ensure `CIVITAI_TOKEN` is set

### GPU Not Detected

1. Verify NVIDIA drivers: `nvidia-smi`
2. Check Docker GPU runtime: `docker run --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi`
3. Ensure `--gpus all` flag is used

### Out of Memory

Use VRAM optimizations:
```bash
-e EXTRA_ARGS="--lowvram"
# or for very limited VRAM:
-e EXTRA_ARGS="--novram"
```

## Architecture

This setup combines:
- **comfyui-docker**: Production-grade base with NGINX, App Manager, persistent sync
- **run-comfyui-image**: Runtime model provisioning capabilities
- **50+ Custom Nodes**: Extended functionality out of the box

## License

This Docker setup integrates various open-source projects. Refer to individual component licenses:
- ComfyUI: GPL-3.0
- Custom nodes: Various (see respective repositories)

## Credits

Built on top of:
- [ashleykza/comfyui-docker](https://github.com/ashleykza/runpod-worker-comfy)
- ComfyUI community custom nodes
- RunPod infrastructure optimizations

## Support

For issues specific to this Docker setup:
- Check the troubleshooting section above
- Review container logs
- Ensure all prerequisites are met (GPU drivers, Docker, etc.)

For ComfyUI-specific issues:
- Visit [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- Check [ComfyUI Documentation](https://docs.comfy.org)
