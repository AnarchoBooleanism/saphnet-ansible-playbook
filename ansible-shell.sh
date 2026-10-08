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

# As well, by default, the Docker container will run with the UID and GID of the current
# shell. To set a custom UID/GID, set the environment variables, PUID and/or PGID!

# To set extra arguments to pass to "docker run", set the DOCKER_ARGS environment variable.
# It is also assumed that the workspace directory (containing the Ansible playbook and
# prod-shell) is the current working directory of the shell. If this is not, then you can
# set the WORKSPACE_DIR environment variable with your desired location.

# Example usage:
# ./ansible-shell.sh: Runs the default entrypoint (/bin/bash)
# ./ansible-shell.sh echo test: Prints "test" from within the container
# ./ansible-shell.sh ansible --help: Prints help documentation for the "ansible" command

# Exit on any failure
set -e

WORKSPACE_DIR="${WORKSPACE_DIR:-$(pwd)}"
IMAGE_TAG="saphnet-ansible-playbook-prod-shell"
BUILD_CONTEXT="${WORKSPACE_DIR}/prod-shell"
NIX_CACHE_VOLUME="ansible-shell-nix-cache"

# Whether to use host's Nix store or dedicated cache volume
if [ "$ANSIBLE_SHELL_USE_HOST_NIX" == "true" ]; then
    NIX_STORE_VOLUME_OPTIONS="-v /nix:/nix:ro \
        -v /nix/var/nix/daemon-socket/socket:/nix/var/nix/daemon-socket/socket \
        -e NIX_REMOTE=unix:///nix/var/nix/daemon-socket/socket"
else
    NIX_STORE_VOLUME_OPTIONS="-v $NIX_CACHE_VOLUME:/nix"
fi

if [ ! -d "$BUILD_CONTEXT" ]; then
    printf "Error: Directory %s not found in the current working directory.\n" "${BUILD_CONTEXT}" >&2
    exit 1
fi

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    printf "Error: Docker is not installed or not in your PATH.\n" >&2
    exit 1
fi

printf "Creating Docker image from dev-container/Dockerfile... (this may take some time)\n"
docker build -t "$IMAGE_TAG" "$BUILD_CONTEXT"

if [ "$ANSIBLE_SHELL_USE_HOST_NIX" != "true" ]; then
    printf "If the Nix cache volume isn't created, creating now...\n"
    docker volume create "$NIX_CACHE_VOLUME"
fi

printf "Now running...\n"

exec docker run -it --rm \
    $DOCKER_ARGS \
    -e "PUID=${PUID:-$(id -u)}" \
    -e "PGID=${PGID:-$(id -g)}" \
    $NIX_STORE_VOLUME_OPTIONS \
    -v "${WORKSPACE_DIR}:/workspace" \
    -w /workspace \
    "$IMAGE_TAG" "$@"