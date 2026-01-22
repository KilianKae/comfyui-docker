ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Copy the build scripts
WORKDIR /
COPY --chmod=755 build/*.sh /build/

# Phase 1: Install ComfyUI base
ARG TORCH_VERSION
ARG XFORMERS_VERSION
ARG INDEX_URL
ARG COMFYUI_COMMIT
RUN /build/install_comfyui.sh

# Phase 2: Install 50+ custom nodes
RUN /build/install_custom_nodes.sh

# Phase 3: Install Application Manager
ARG APP_MANAGER_VERSION
RUN /build/install_app_manager.sh
COPY app-manager/config.json /app-manager/public/config.json
COPY --chmod=755 app-manager/*.sh /app-manager/scripts/

# Phase 4: Install CivitAI downloader
ARG CIVITAI_DOWNLOADER_VERSION
RUN /build/install_civitai_model_downloader.sh

# Phase 5: Install model downloading tools (HF CLI, etc.)
RUN /build/install_model_tools.sh

# Cleanup installation scripts
RUN rm -rf /build

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# Copy NGINX configuration
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Copy runtime scripts
WORKDIR /
COPY --chmod=755 scripts/*.sh ./
COPY --chmod=755 start-production.sh /start-production.sh

# Set template version
ARG RELEASE
ENV TEMPLATE_VERSION=${RELEASE}

# Set the main venv path
ARG VENV_PATH
ENV VENV_PATH=${VENV_PATH}

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start-production.sh" ]
