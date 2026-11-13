# Container for running the Ansible playbooks in, with all necessary packages included
## Python venv build stage
FROM debian:13.7-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4 AS venv-builder
COPY --from=ghcr.io/astral-sh/uv:0.13.7@sha256:96f40d3904aad8d0bd010539001d36c8e2188b981e1334471a90c4a1d93bb490 /uv /uvx /bin/

WORKDIR /setup
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_PROJECT_ENVIRONMENT="/opt/venv"
ENV UV_PYTHON_INSTALL_DIR="/opt/python"
ENV PATH="$UV_PROJECT_ENVIRONMENT/bin:/opt/python/bin:$PATH"

COPY pyproject.toml uv.lock .python-version ./
RUN mkdir -p /opt/venv /opt/python && \
    uv sync --frozen --no-install-project
    
## Main build stage
FROM debian:13.7-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4

# Set up base environment
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget curl nano gnupg git openssh-server sshpass \
    nix gosu passwd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=venv-builder /opt/python /opt/python
COPY --from=venv-builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:/opt/python/bin:$PATH"

# renovate: datasource=github-tags depName=NixOS/nixpkgs
ARG NIXPKGS_VERSION=v208

# Configure nix
RUN nix-channel --add https://nixos.org/channels/nixos-$NIXPKGS_VERSION nixpkgs \
    && nix-channel --update
COPY nix.conf /etc/nix/

# Entrypoint
COPY entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV HOME="/home/ansible"
ENV ANSIBLE_LOCAL_TEMP="/tmp"
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]