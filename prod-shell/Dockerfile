# Container for running the Ansible playbooks in, with all necessary packages included
FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a
# TODO: Have auto-update for nixpkgs version
ENV NIXPKGS_VERSION=26.05

# Install necessary Alpine packages
RUN apk update
RUN apk add --no-cache bash git nix openssh python3 py3-pip py3-virtualenv sshpass su-exec shadow

# Create Python virtual environment to install stuff in
ENV VIRTUAL_ENV="/opt/venv"
RUN python -m venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install pip packages (including Ansible)
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt 

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