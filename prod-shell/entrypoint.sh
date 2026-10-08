#!/bin/bash
# Entrypoint for container itself, creating custom users/groups

set -e

# The aim is to be able to use the exact numerical IDs as specified from
# the host, even if the names don't match.
# To do this, we need to map to existing users/groups, and if those
# don't exist, then create them.

USER_ID=${PUID:-0}
GROUP_ID=${PGID:-0}

USER_NAME="ansible"
GROUP_NAME="users"

EXISTING_GROUP=$(getent group "$GROUP_ID" | cut -d: -f1 || true)

if [ -n "$EXISTING_GROUP" ]; then
    ACTUAL_GROUP="$EXISTING_GROUP"
else
    groupmod -g "$GROUP_ID" "$GROUP_NAME"
    ACTUAL_GROUP="$GROUP_NAME"
fi

EXISTING_USER=$(getent passwd "$USER_ID" | cut -d: -f1 || true)

# In any case, we want our user to be part of the group (mapped to the host's GID)
if [ -n "$EXISTING_USER" ]; then
    ACTUAL_USER="$EXISTING_USER"
    usermod -a "$ACTUAL_GROUP" "$ACTUAL_USER" >/dev/null 2>&1 || true
else
    ACTUAL_USER="$USER_NAME"
    adduser -D -u "$USER_ID" -G "$ACTUAL_GROUP" -h "/home/$USER_NAME" "$USER_NAME"
fi

if [ $# -eq 0 ]; then
    # Default behavior
    exec su-exec "$USER_ID" /bin/bash
else
    exec su-exec "$USER_ID" "$@"
fi