#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

NEW_VERSION="$1"
if [ -z "$NEW_VERSION" ]; then
    CURRENT=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)
    CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Resources/Info.plist 2>/dev/null || echo "1")
    echo "Current version: $CURRENT (build $CURRENT_BUILD)"
    echo ""
    echo "Usage: ./bump-version.sh <new_version> [optional commit message]"
    echo "Example: ./bump-version.sh 1.2.0"
    exit 1
fi

# Remove leading 'v' if provided (e.g. v1.2.0 -> 1.2.0)
NEW_VERSION="${NEW_VERSION#v}"

# Get current build number and increment
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Resources/Info.plist 2>/dev/null || echo "1")
NEW_BUILD=$((CURRENT_BUILD + 1))

# Update Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" Resources/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" Resources/Info.plist

echo "✅ Updated Resources/Info.plist to version $NEW_VERSION (build $NEW_BUILD)"

# Verify build passes
echo "🔨 Verifying local build..."
./build.sh

# Commit and push
COMMIT_MSG="${2:-chore(release): bump version to v$NEW_VERSION}"
git add Resources/Info.plist
git commit -m "$COMMIT_MSG"
echo "✅ Committed version bump."

echo "🚀 Pushing to origin main..."
git push origin main
echo "🎉 Pushed! GitHub Actions will now automatically build and publish release v$NEW_VERSION on GitHub."
