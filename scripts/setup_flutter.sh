#!/usr/bin/env bash

set -euo pipefail

# Resolve the repository root so the script works from CI or Vercel.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Install Flutter into the repository workspace when the SDK is not available.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.0}"
FLUTTER_DIR="${FLUTTER_DIR:-$ROOT_DIR/.flutter-sdk}"
FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"

if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Flutter SDK not found. Downloading Flutter $FLUTTER_VERSION into $FLUTTER_DIR..."
  rm -rf "$FLUTTER_DIR"
  mkdir -p "$FLUTTER_DIR"

  FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_ARCHIVE}"

  echo "Downloading from: $FLUTTER_URL"
  curl -fsSL "$FLUTTER_URL" -o "/tmp/${FLUTTER_ARCHIVE}"

  echo "Extracting Flutter SDK..."
  tar xf "/tmp/${FLUTTER_ARCHIVE}" -C "$ROOT_DIR"
  mv "$ROOT_DIR/flutter" "$FLUTTER_DIR"
  rm -f "/tmp/${FLUTTER_ARCHIVE}"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# Emit the resolved SDK version so CI logs show which toolchain was used.
flutter --version