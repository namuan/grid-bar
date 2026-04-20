#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="GridBar"
CONFIGURATION="release"
DEST_DIR="$HOME/Applications"
DEST_APP="$DEST_DIR/$APP_NAME.app"
OPEN_AFTER=false

for arg in "$@"; do
    case "$arg" in
        --open) OPEN_AFTER=true ;;
        --debug) CONFIGURATION="debug" ;;
    esac
done

echo "Building $APP_NAME ($CONFIGURATION) with Swift Package Manager..."
cd "$SCRIPT_DIR"
swift build -c "$CONFIGURATION" 2>&1

EXECUTABLE="$SCRIPT_DIR/.build/$CONFIGURATION/$APP_NAME"
if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: built executable not found at $EXECUTABLE"
    exit 1
fi

# Assemble the .app bundle
BUNDLE="$SCRIPT_DIR/.build/$APP_NAME.app"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"

cp "$EXECUTABLE" "$BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>GridBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.gridbar.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>GridBar</string>
    <key>CFBundleDisplayName</key>
    <string>GridBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
EOF

printf 'APPL????' > "$BUNDLE/Contents/PkgInfo"

# Strip all extended attributes (quarantine flags etc.)
xattr -cr "$BUNDLE"

# Ad-hoc sign so macOS will launch it
codesign --force --deep --sign - "$BUNDLE" 2>/dev/null || true

/bin/mkdir -p "$DEST_DIR"

if [ -d "$DEST_APP" ]; then
    echo "Removing existing install..."
    /bin/rm -rf "$DEST_APP"
fi

echo "Resetting existing TCC permissions for $APP_NAME..."
tccutil reset All com.gridbar.app 2>/dev/null || true

echo "Installing to: $DEST_APP"
/usr/bin/ditto "$BUNDLE" "$DEST_APP"

if $OPEN_AFTER; then
    echo "Opening $APP_NAME..."
    open "$DEST_APP"
fi

echo "Done."
