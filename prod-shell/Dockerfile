# Container for running the Ansible playbooks in, with all necessary packages included
FROM alpine:3.23.0
ENV NIXPKGS_VERSION=25.11

# Install necessary Alpine packages
RUN apk update
RUN apk add --no-cache bash git nix openssh python3 py3-pip py3-virtualenv

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

ENV HOME="/home/user"
ENTRYPOINT ["/bin/bash"]