#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$DIR/build/DefaultBrowserChanger.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Creating bundle structure..."
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "Copying Info.plist and Resources..."
cp "$DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

SWIFT_FILES=$(find "$DIR/Sources" -name "*.swift" 2>/dev/null || true)

if [ -n "$SWIFT_FILES" ]; then
    echo "Compiling Swift sources..."
    swiftc -O -target arm64-apple-macos13.0 \
        -framework AppKit \
        -framework ApplicationServices \
        -framework ServiceManagement \
        -framework UserNotifications \
        $SWIFT_FILES \
        -o "$MACOS_DIR/DefaultBrowserChanger"

    echo "Codesigning app bundle..."
    codesign --force --deep --sign - "$APP_DIR"
    echo "Build completed successfully at: $APP_DIR"
else
    echo "No Swift sources found in Sources/. Bundle scaffolding prepared."
fi

if [ "$1" = "--install" ]; then
    if [ ! -f "$MACOS_DIR/DefaultBrowserChanger" ]; then
        echo "Error: Cannot install. Executable not found at $MACOS_DIR/DefaultBrowserChanger"
        exit 1
    fi
    echo "Installing to /Applications/DefaultBrowserChanger.app..."
    rm -rf /Applications/DefaultBrowserChanger.app
    cp -R "$APP_DIR" /Applications/DefaultBrowserChanger.app
    echo "Successfully installed to /Applications/DefaultBrowserChanger.app"
fi
