variable "REGISTRY" {
    default = "docker.io"
}

variable "REGISTRY_USER" {
    default = "kiliankaeslin"
}

variable "APP" {
    default = "comfy-5090-custom-2"
}

variable "RELEASE" {
    default = "1.0.5"
}

variable "RELEASE_SUFFIX" {
    default = ""
}

variable "BASE_IMAGE_REPOSITORY" {
    default = "ashleykza/runpod-base"
}

variable "BASE_IMAGE_VERSION" {
    default = "2.4.11"
}

variable "APP_MANAGER_VERSION" {
    default = "1.3.1"
}

variable "CIVITAI_DOWNLOADER_VERSION" {
    default = "2.1.0"
}

variable "COMFYUI_COMMIT" {
    default = "HEAD"
}

group "default" {
    targets = ["cu128-py312"]
}

group "all" {
    targets = [
        "cu124-py311",
        "cu124-py312",
        "cu128-py311",
        "cu128-py312"
    ]
}

target "cu124-py311" {
    dockerfile = "Dockerfile"
    tags = ["${REGISTRY}/${REGISTRY_USER}/${APP}:cu124-py311-${RELEASE}${RELEASE_SUFFIX}"]
    args = {
        RELEASE                    = "${RELEASE}"
        BASE_IMAGE                 = "${BASE_IMAGE_REPOSITORY}:${BASE_IMAGE_VERSION}-python3.11-cuda12.4.1-torch2.6.0"
        INDEX_URL                  = "https://download.pytorch.org/whl/cu124"
        TORCH_VERSION              = "2.6.0+cu124"
        XFORMERS_VERSION           = "0.0.29.post3"
        COMFYUI_COMMIT             = "${COMFYUI_COMMIT}"
        APP_MANAGER_VERSION        = "${APP_MANAGER_VERSION}"
        CIVITAI_DOWNLOADER_VERSION = "${CIVITAI_DOWNLOADER_VERSION}"
    }
    platforms = ["linux/amd64"]
}

target "cu124-py312" {
    dockerfile = "Dockerfile"
    tags = ["${REGISTRY}/${REGISTRY_USER}/${APP}:cu124-py312-${RELEASE}${RELEASE_SUFFIX}"]
    args = {
        RELEASE                    = "${RELEASE}"
        BASE_IMAGE                 = "${BASE_IMAGE_REPOSITORY}:${BASE_IMAGE_VERSION}-python3.12-cuda12.4.1-torch2.6.0"
        INDEX_URL                  = "https://download.pytorch.org/whl/cu124"
        TORCH_VERSION              = "2.6.0+cu124"
        XFORMERS_VERSION           = "0.0.29.post3"
        COMFYUI_COMMIT             = "${COMFYUI_COMMIT}"
        APP_MANAGER_VERSION        = "${APP_MANAGER_VERSION}"
        CIVITAI_DOWNLOADER_VERSION = "${CIVITAI_DOWNLOADER_VERSION}"
    }
    platforms = ["linux/amd64"]
}

target "cu128-py311" {
    dockerfile = "Dockerfile"
    tags = ["${REGISTRY}/${REGISTRY_USER}/${APP}:cu128-py311-${RELEASE}${RELEASE_SUFFIX}"]
    args = {
        RELEASE                    = "${RELEASE}"
        BASE_IMAGE                 = "${BASE_IMAGE_REPOSITORY}:${BASE_IMAGE_VERSION}-python3.11-cuda12.8.1-torch2.9.1"
        INDEX_URL                  = "https://download.pytorch.org/whl/cu128"
        TORCH_VERSION              = "2.9.1+cu128"
        XFORMERS_VERSION           = "0.0.33"
        COMFYUI_COMMIT             = "${COMFYUI_COMMIT}"
        APP_MANAGER_VERSION        = "${APP_MANAGER_VERSION}"
        CIVITAI_DOWNLOADER_VERSION = "${CIVITAI_DOWNLOADER_VERSION}"
    }
    platforms = ["linux/amd64"]
}

target "cu128-py312" {
    dockerfile = "Dockerfile"
    tags = ["${REGISTRY}/${REGISTRY_USER}/${APP}:${RELEASE}${RELEASE_SUFFIX}"]
    args = {
        RELEASE                    = "${RELEASE}"
        BASE_IMAGE                 = "${BASE_IMAGE_REPOSITORY}:${BASE_IMAGE_VERSION}-python3.12-cuda12.8.1-torch2.9.1"
        INDEX_URL                  = "https://download.pytorch.org/whl/cu128"
        TORCH_VERSION              = "2.9.1+cu128"
        XFORMERS_VERSION           = "0.0.33"
        COMFYUI_COMMIT             = "${COMFYUI_COMMIT}"
        APP_MANAGER_VERSION        = "${APP_MANAGER_VERSION}"
        CIVITAI_DOWNLOADER_VERSION = "${CIVITAI_DOWNLOADER_VERSION}"
    }
    platforms = ["linux/amd64"]
}
