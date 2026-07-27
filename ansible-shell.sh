#!/bin/sh

# This script allows you to input any command and have it run in a container based
# on the Dockerfile, with everything correctly mounted.
# It is assumed that your host's working directory is the root directory of the
# repository; the container's working directory will be /workspace.

# By default, the Docker container will come with a volume attached to "/nix" on
# the container, to cache builds between runs.
# If, instead, you want to use the Nix store of the host (to reduce total space used),
# you can set the ANSIBLE_SHELL_USE_HOST_NIX environment variable to "true".
# Example: ANSIBLE_SHELL_USE_HOST_NIX=true ./ansible-shell.sh

# Example usage:
# ./ansible-shell.sh: Runs the default entrypoint (/bin/bash)
# ./ansible-shell.sh /bin/bash -c "echo test": Prints "test" from within the container
# ./ansible-shell.sh ansible --help: Prints help documentation for the "ansible" command

# Exit on any failure
set -e

IMAGE_TAG="saphnet-ansible-playbook-prod-shell"
BUILD_CONTEXT="$(pwd)/prod-shell"
NIX_CACHE_VOLUME="ansible-shell-nix-cache"

# Whether to use host's Nix store or dedicated cache volume
if [ "$ANSIBLE_SHELL_USE_HOST_NIX" == "true" ]; then
    NIX_STORE_VOLUME_OPTIONS="-v /nix:/nix:ro \
        -v /nix/var/nix/daemon-socket/socket:/nix/var/nix/daemon-socket/socket \
        -e NIX_REMOTE=unix:///nix/var/nix/daemon-socket/socket"
else
    NIX_STORE_VOLUME_OPTIONS="-v $NIX_CACHE_VOLUME:/nix"
fi

# Final list of arguments to use for running Docker image
DOCKER_ARGS="-it --rm \
            $NIX_STORE_VOLUME_OPTIONS \
            -v "$(pwd)":/workspace \
            -w /workspace"

if [ ! -d "$BUILD_CONTEXT" ]; then
    echo "Error: Directory $BUILD_CONTEXT not found in the current working directory." >&2
    exit 1
fi

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is not installed or not in your PATH." >&2
    exit 1
fi

echo "Creating Docker image from dev-container/Dockerfile... (this may take some time)"
docker build -t "$IMAGE_TAG" "$BUILD_CONTEXT"

if [ "$ANSIBLE_SHELL_USE_HOST_NIX" != "true" ]; then
    echo "If the Nix cache volume isn't created, creating now..."
    docker volume create "$NIX_CACHE_VOLUME"
fi

echo "Now running..."
if [ $# -eq 0 ]; then
    exec docker run $DOCKER_ARGS "$IMAGE_TAG"
else
    # Allows us to easily just pass in any command to be run within Bash
    exec docker run $DOCKER_ARGS --entrypoint "/bin/bash" "$IMAGE_TAG" -c "$*"
fi