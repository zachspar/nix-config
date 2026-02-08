#!/usr/bin/env bash
# Script to prefetch DisplayLink driver for NixOS
# This needs to be run once to add the driver to the nix store

set -euo pipefail

DISPLAYLINK_URL="https://www.synaptics.com/sites/default/files/exe_files/2025-09/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.2-EXE.zip"
DISPLAYLINK_NAME="displaylink-620.zip"

echo "Prefetching DisplayLink driver..."
echo "URL: $DISPLAYLINK_URL"
echo ""

# Run nix-prefetch-url to add the driver to the nix store
nix-prefetch-url --name "$DISPLAYLINK_NAME" "$DISPLAYLINK_URL"

echo ""
echo "DisplayLink driver prefetch complete!"
echo "You can now rebuild your NixOS configuration."

