@echo off
echo === MCHS Mobile App — Setup ===

where flutter >nul 2>&1
if %errorlevel% neq 0 (
  echo ERROR: Flutter not found. Install Flutter SDK 3.9.2+ from https://flutter.dev/docs/get-started/install
  exit /b 1
)

echo.
echo Flutter version:
flutter --version

echo.
echo [1/2] Installing dependencies...
flutter pub get
if %errorlevel% neq 0 exit /b %errorlevel%

echo.
echo [2/2] Generating code (Freezed / Riverpod / JSON)...
dart run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 exit /b %errorlevel%

echo.
echo === Setup complete! ===
echo Run the app with:
echo   flutter run
