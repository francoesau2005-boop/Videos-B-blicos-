#!/bin/bash
# Compila la app Rotísimo. Requiere el SDK de Android (ANDROID_HOME) y Gradle 8.9+.
set -e
cd "$(dirname "$0")"
mkdir -p dist app_android/app/src/main/assets
cp web/index.html app_android/app/src/main/assets/index.html
cd app_android
echo "sdk.dir=${ANDROID_HOME:-/opt/android-sdk}" > local.properties
gradle --no-daemon -q assembleRelease
cp app/build/outputs/apk/release/app-release.apk ../dist/Rotisimo.apk
echo "APK: dist/Rotisimo.apk"
