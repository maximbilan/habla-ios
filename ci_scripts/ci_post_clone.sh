#!/bin/bash
# ci_post_clone.sh - Xcode Cloud: generate Sources/Config/Config.swift

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRCROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$SRCROOT/Sources/Config"
OUTPUT_FILE="$OUTPUT_DIR/Config.swift"
ENV_FILE="$SRCROOT/.env"

# Prefer Xcode Cloud environment variable, fallback to local .env.
BACKEND_URL="${HABLA_BACKEND_URL:-}"
if [[ -z "$BACKEND_URL" && -f "$ENV_FILE" ]]; then
  BACKEND_URL=$(grep -E '^HABLA_BACKEND_URL=' "$ENV_FILE" | head -n 1 | cut -d '=' -f2- | sed 's/^"//;s/"$//' | tr -d '\r' || true)
fi

if [[ -z "$BACKEND_URL" ]]; then
  echo "❌ Missing HABLA_BACKEND_URL. Set it in Xcode Cloud env vars or .env."
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

cat > "$OUTPUT_FILE" <<EOF
import Foundation

// Auto-generated. Do not edit.
// Generated on $(date)
enum AppConfig {
    static let backendURL = "$BACKEND_URL"
}
EOF

echo "✅ Generated $OUTPUT_FILE"
