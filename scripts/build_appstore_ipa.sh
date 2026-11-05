#!/bin/bash
set -e

echo "=================================================="
echo " CineFlix Media - App Store Production Build Script"
echo "=================================================="

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "[1/5] Pulling latest origin/master..."
git pull origin master

echo "[2/5] Cleaning build artifacts..."
flutter clean

echo "[3/5] Fetching Flutter dependencies..."
flutter pub get

echo "[4/5] Setting up iOS CocoaPods..."
cd ios
pod install
cd ..

echo "[5/5] Building Production Archive and IPA..."
flutter build ipa --release

ARCHIVE_PATH="$PROJECT_DIR/build/ios/archive/Runner.xcarchive"
IPA_DIR="$PROJECT_DIR/build/ios/ipa"
IPA_FILE=$(find "$IPA_DIR" -name "*.ipa" -type f | head -n 1)

if [ -f "$IPA_FILE" ]; then
    echo "=================================================="
    echo " BUILD SUCCESSFUL!"
    echo "=================================================="
    echo "Archive Path: $ARCHIVE_PATH"
    echo "IPA Path:     $IPA_FILE"
    echo "IPA Size:     $(ls -lh "$IPA_FILE" | awk '{print $5}')"
    echo "SHA256:       $(shasum -a 256 "$IPA_FILE" | awk '{print $1}')"
    echo "=================================================="
    echo ""
    echo "Signing Verification:"
    codesign -dvvv --entitlements :- "$ARCHIVE_PATH/Products/Applications/Runner.app" 2>&1 | grep -E "Authority|TeamIdentifier|Identifier|com.apple.developer" || true
    echo "=================================================="
else
    echo "ERROR: IPA file not generated in $IPA_DIR"
    exit 1
fi
