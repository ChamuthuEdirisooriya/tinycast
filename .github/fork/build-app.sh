#!/bin/bash
# Builds and zips Tinycast Fork.app into $RUNNER_TEMP/dist. Usage: build-app.sh [version]
# Signed with the fork certificate when its secrets are set: an update must carry that same leaf.
set -euo pipefail
VERSION="${1:-}"
: "${APP_NAME:?}" "${APP_BUNDLE_ID:?}" "${SIGNING_IDENTITY:?}"

if [ -n "${SIGNING_P12_BASE64:-}" ]; then
    KEYCHAIN="$RUNNER_TEMP/signing.keychain-db"
    KPW="$(openssl rand -base64 24)"
    echo "$SIGNING_P12_BASE64" | base64 --decode > "$RUNNER_TEMP/cert.p12"
    security create-keychain -p "$KPW" "$KEYCHAIN"
    security set-keychain-settings -lut 21600 "$KEYCHAIN"
    security unlock-keychain -p "$KPW" "$KEYCHAIN"
    security import "$RUNNER_TEMP/cert.p12" -k "$KEYCHAIN" -P "${SIGNING_P12_PASSWORD:-}" \
        -A -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple: -s -k "$KPW" "$KEYCHAIN" >/dev/null
    security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | sed 's/"//g')
    rm -f "$RUNNER_TEMP/cert.p12"
    IDENTITY="$SIGNING_IDENTITY"
elif [ "${REQUIRE_SIGNING:-0}" = 1 ]; then
    echo "::error::FORK_SIGNING_P12_BASE64 is not set; a published build must carry the fork certificate"
    exit 1
else
    echo "::warning::No signing secrets, so this build is ad-hoc signed and can never update itself"
    IDENTITY="-"
fi

VERSION_ARGS=()
[ -n "$VERSION" ] && VERSION_ARGS=(MARKETING_VERSION="$VERSION")
xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Release \
    -derivedDataPath "$RUNNER_TEMP/DerivedData" \
    ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" \
    OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
    PRODUCT_NAME="$APP_NAME" TINYCAST_BUNDLE_IDENTIFIER="$APP_BUNDLE_ID" \
    CURRENT_PROJECT_VERSION="$GITHUB_RUN_NUMBER" \
    ${VERSION_ARGS[@]+"${VERSION_ARGS[@]}"} \
    build

APP="$RUNNER_TEMP/DerivedData/Build/Products/Release/$APP_NAME.app"
PLIST="$APP/Contents/Info.plist"
ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST")"
[ "$ID" = "$APP_BUNDLE_ID" ] || { echo "::error::Bundle id is '$ID', expected '$APP_BUNDLE_ID'"; exit 1; }
BUILT="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
if [ -n "$VERSION" ] && [ "$BUILT" != "$VERSION" ]; then
    echo "::error::Built version is '$BUILT', expected '$VERSION'"
    exit 1
fi
echo "Built $APP_NAME $BUILT ($ID), $(lipo -archs "$APP/Contents/MacOS/$APP_NAME"), signed by $IDENTITY"
./Scripts/verify-signature.sh "$APP"

mkdir -p "$RUNNER_TEMP/dist"
# `ditto` keeps the seal intact, and a name without "-Universal-" is the one Apple silicon takes.
ditto -c -k --keepParent --sequesterRsrc "$APP" "$RUNNER_TEMP/dist/Tinycast-Fork-$BUILT.zip"
