#!/bin/bash
# Points DEVELOPER_DIR for later steps at the newest Xcode 26 on the runner.
set -euo pipefail
XCODE_PATH="$(ls -d /Applications/Xcode_26*.app 2>/dev/null | sort -V | tail -n1)"
if [ -z "$XCODE_PATH" ]; then
    echo "::error::No Xcode 26.x on this runner. Installed Xcodes:"
    ls /Applications | grep -i xcode || true
    exit 1
fi
echo "Using $XCODE_PATH"
echo "DEVELOPER_DIR=$XCODE_PATH/Contents/Developer" >> "$GITHUB_ENV"
