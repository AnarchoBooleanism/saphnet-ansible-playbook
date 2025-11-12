#!/bin/sh

# This script allows you to input any command and have it run in a container based
# on the Dockerfile, with everything correctly mounted.
# It is assumed that your host's working directory is the root directory of the
# repository; the container's working directory will be /workspace.
# Example usage:
# ./ansible-shell.sh: Runs the default entrypoint (/bin/bash)
# ./ansible-shell.sh /bin/bash -c "echo test": Prints "test" from within the container
# ./ansible-shell.sh ansible --help: Prints help documentation for the "ansible" command

# Exit on any failure
set -e

IMAGE_TAG="saphnet-ansible-playbook-prod-shell"
BUILD_CONTEXT="$(pwd)/prod-shell"
DOCKER_ARGS="-it --rm \
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

echo "Now running..."
if [ $# -eq 0 ]; then
    exec docker run $DOCKER_ARGS "$IMAGE_TAG"
else
    # Allows us to easily just pass in any command to be run within Bash
    exec docker run $DOCKER_ARGS --entrypoint "/bin/bash" "$IMAGE_TAG" -c "$*"
fi