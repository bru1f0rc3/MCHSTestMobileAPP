#!/usr/bin/env bash
set -e

echo "=== MCHS Mobile App — Setup ==="

if ! command -v flutter &> /dev/null; then
  echo "ERROR: Flutter not found. Install Flutter SDK 3.9.2+ from https://flutter.dev/docs/get-started/install"
  exit 1
fi

echo ""
echo "Flutter version:"
flutter --version

echo ""
echo "[1/2] Installing dependencies..."
flutter pub get

echo ""
echo "[2/2] Generating code (Freezed / Riverpod / JSON)..."
dart run build_runner build --delete-conflicting-outputs

echo ""
echo "=== Setup complete! ==="
echo "Run the app with:"
echo "  flutter run"
