#!/bin/bash
# Points DEVELOPER_DIR for later steps at the newest released Xcode 27, as upstream's release does.
set -euo pipefail
# Real folders only: an image's Xcode_27.N.app symlink can point at a release candidate.
XCODE_PATH="$(find -E /Applications -maxdepth 1 -type d -regex '.*/Xcode_27(\.[0-9]+)*\.app' | sort -V | tail -n1)"
if [ -z "$XCODE_PATH" ]; then
    echo "::error::No released Xcode 27.x on this runner. Installed Xcodes:"
    ls /Applications | grep -i xcode || true
    exit 1
fi
echo "Using $XCODE_PATH"
echo "DEVELOPER_DIR=$XCODE_PATH/Contents/Developer" >> "$GITHUB_ENV"
