#!/bin/bash
set -euo pipefail

# Build native notification apps with custom icons.
# Each app is a proper macOS app bundle with UNUserNotificationCenter,
# so macOS shows the app's own icon in notifications.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ICONS_DIR="$SCRIPT_DIR/../icons"
APPS_DIR="$HOME/Applications/Notifiers"

mkdir -p "$APPS_DIR"

# Compile the Swift notification binary once
BINARY=$(mktemp)
swiftc -O -o "$BINARY" "$SCRIPT_DIR/notify.swift" -framework UserNotifications
echo "Compiled notify binary"

for entry in "GmailNotify:com.maggieyi.gmail.notify:gmail:Gmail" \
             "CalNotify:com.maggieyi.gcal.notify:gcal:Google Calendar" \
             "ClaudeNotify:com.maggieyi.claude.notify:claude:Claude Code"; do
    IFS=':' read -r name bundle_id icon_name display_name <<< "$entry"
    APP="$APPS_DIR/$name.app"
    rm -rf "$APP"

    # Create app bundle structure
    mkdir -p "$APP/Contents/MacOS"
    mkdir -p "$APP/Contents/Resources"

    # Copy binary
    cp "$BINARY" "$APP/Contents/MacOS/$name"
    chmod +x "$APP/Contents/MacOS/$name"

    # Build icns from PNG
    SRC="$ICONS_DIR/${icon_name}.png"
    ICONSET=$(mktemp -d)/AppIcon.iconset
    mkdir -p "$ICONSET"
    sips -z 16 16 "$SRC" --out "$ICONSET/icon_16x16.png" &>/dev/null
    sips -z 32 32 "$SRC" --out "$ICONSET/icon_16x16@2x.png" &>/dev/null
    sips -z 32 32 "$SRC" --out "$ICONSET/icon_32x32.png" &>/dev/null
    sips -z 64 64 "$SRC" --out "$ICONSET/icon_32x32@2x.png" &>/dev/null
    sips -z 128 128 "$SRC" --out "$ICONSET/icon_128x128.png" &>/dev/null
    sips -z 256 256 "$SRC" --out "$ICONSET/icon_128x128@2x.png" &>/dev/null
    sips -z 256 256 "$SRC" --out "$ICONSET/icon_256x256.png" &>/dev/null
    sips -z 512 512 "$SRC" --out "$ICONSET/icon_256x256@2x.png" &>/dev/null
    sips -z 512 512 "$SRC" --out "$ICONSET/icon_512x512.png" &>/dev/null
    cp "$SRC" "$ICONSET/icon_512x512@2x.png"
    iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

    # Create Info.plist
    cat > "$APP/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>${bundle_id}</string>
    <key>CFBundleName</key>
    <string>${display_name}</string>
    <key>CFBundleDisplayName</key>
    <string>${display_name}</string>
    <key>CFBundleExecutable</key>
    <string>${name}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSUserNotificationAlertStyle</key>
    <string>banner</string>
</dict>
</plist>
PLIST

    # Ad-hoc sign
    codesign --force --deep --sign - "$APP"

    # Remove quarantine
    xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

    # Register with Launch Services
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

    echo "$display_name → $APP"
done

rm -f "$BINARY"
echo ""
echo "Done. Allow notifications for each app in System Settings > Notifications."
