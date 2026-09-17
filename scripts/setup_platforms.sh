#!/usr/bin/env bash
set -euo pipefail
flutter create --platforms=android,ios .
flutter pub get
dart run flutter_launcher_icons
flutter analyze
