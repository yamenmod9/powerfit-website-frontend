#!/usr/bin/env bash

set -euo pipefail

# Install Flutter if needed, then resolve Dart/Flutter packages.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/setup_flutter.sh"
flutter pub get