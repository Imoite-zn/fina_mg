@echo off
REM Flutter Web Build Script for Windows
REM This script builds the Flutter web app with the correct flags

echo Building Flutter web app...
flutter build web --release --no-tree-shake-icons

echo Build complete! Output is in build\web\
