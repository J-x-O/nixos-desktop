#!/usr/bin/env bash
# Sets up rclone gdrive remote if not already configured

REMOTE="gdrive"

if rclone listremotes | grep -q "^${REMOTE}:"; then
  echo "rclone remote '${REMOTE}' already configured, nothing to do."
  exit 0
fi

echo "No rclone remote '${REMOTE}' found. Starting Google Drive authentication..."
# Pre-fills: type=drive, scope=full access, no custom client id/secret
rclone config create "$REMOTE" drive \
  scope drive \
  client_id "" \
  client_secret "" && \
  echo "Done! Restarting mount service..." && \
  systemctl --user restart "rclone-${REMOTE}-*"
