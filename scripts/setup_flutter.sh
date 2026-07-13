#!/usr/bin/env bash

set -euo pipefail

# Resolve the repository root so the script works from CI or Vercel.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Install Flutter into the repository workspace when the SDK is not available.
FLUTTER_DIR="${FLUTTER_DIR:-$ROOT_DIR/.flutter-sdk}"
FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"

if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Flutter SDK not found. Installing stable Flutter into $FLUTTER_DIR..."
  rm -rf "$FLUTTER_DIR"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# Emit the resolved SDK version so CI logs show which toolchain was used.
flutter --version