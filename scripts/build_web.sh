#!/usr/bin/env bash

set -euo pipefail

# Resolve the repository root so the script works from any working directory.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Make sure a Flutter SDK is available before building.
# This is required on Vercel, where Flutter is not preinstalled.
source "$ROOT_DIR/scripts/setup_flutter.sh"

# Load local overrides if a developer created a .env file from .env.example.
if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  source .env
fi

# Keep the build configurable without changing Flutter source code.
ENVIRONMENT="${ENVIRONMENT:-production}"
API_BASE_URL="${API_BASE_URL:-https://yamenmod91.pythonanywhere.com}"

echo "Using ENVIRONMENT: $ENVIRONMENT"
echo "Using API_BASE_URL: $API_BASE_URL"

# Build the production web bundle that Vercel will serve.
flutter config --enable-web
flutter build web --release \
  --dart-define=APP_ENV="$ENVIRONMENT" \
  --dart-define=ENVIRONMENT="$ENVIRONMENT" \
  --dart-define=API_BASE_URL="$API_BASE_URL"