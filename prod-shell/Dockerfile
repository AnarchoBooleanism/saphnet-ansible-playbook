# Container for running the Ansible playbooks in, with all necessary packages included
## Python venv build stage
FROM debian:13.7-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS venv-builder
COPY --from=ghcr.io/astral-sh/uv:0.13.8@sha256:5cc1805e2426484abca4ad46ea783bab281fdb225fd82d8ce6d66a81254bac85 /uv /uvx /bin/

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
FROM debian:13.7-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

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
ARG NIXPKGS_VERSION=26.05

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