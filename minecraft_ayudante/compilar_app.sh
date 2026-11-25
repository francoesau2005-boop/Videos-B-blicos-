#!/bin/bash
# Compila la app Android. Requiere el SDK de Android (ANDROID_HOME) y Gradle 8.9+.
set -e
cd "$(dirname "$0")"
node build.mjs
cd app_android
echo "sdk.dir=${ANDROID_HOME:-/opt/android-sdk}" > local.properties
gradle --no-daemon -q assembleRelease
cp app/build/outputs/apk/release/app-release.apk ../dist/AyudanteSurvival.apk
echo "APK: dist/AyudanteSurvival.apk"
