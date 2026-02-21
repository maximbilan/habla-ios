#!/bin/bash
# ci_post_clone.sh - Xcode Cloud: generate Sources/Config/Config.swift

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRCROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$SRCROOT/Sources/Config"
OUTPUT_FILE="$OUTPUT_DIR/Config.swift"
ENV_FILE="$SRCROOT/.env"

read_env_var() {
  local key="$1"
  local value=""

  if [[ -f "$ENV_FILE" ]]; then
    value=$(grep -E "^${key}=" "$ENV_FILE" | head -n 1 | cut -d '=' -f2- | sed 's/^"//;s/"$//' | tr -d '\r' || true)
  fi

  echo "$value"
}

# Prefer Xcode Cloud environment variable, fallback to local .env.
BACKEND_URL="${HABLA_BACKEND_URL:-}"
if [[ -z "$BACKEND_URL" ]]; then
  BACKEND_URL="$(read_env_var HABLA_BACKEND_URL)"
fi

if [[ -z "$BACKEND_URL" ]]; then
  echo "❌ Missing HABLA_BACKEND_URL. Set it in Xcode Cloud env vars or .env."
  exit 1
fi

HABLA_SECRET_VALUE="${HABLA_SECRET:-}"
if [[ -z "$HABLA_SECRET_VALUE" ]]; then
  HABLA_SECRET_VALUE="$(read_env_var HABLA_SECRET)"
fi

APP_BUNDLE_ID="${HABLA_APP_BUNDLE_ID:-}"
if [[ -z "$APP_BUNDLE_ID" ]]; then
  APP_BUNDLE_ID="$(read_env_var HABLA_APP_BUNDLE_ID)"
fi
if [[ -z "$APP_BUNDLE_ID" ]]; then
  APP_BUNDLE_ID="com.maximbilan.habla-ios"
fi

AUTH_TOKEN=""
if [[ -n "$HABLA_SECRET_VALUE" ]]; then
  AUTH_TOKEN=$(python3 - "$HABLA_SECRET_VALUE" "$APP_BUNDLE_ID" <<'PY'
import hashlib
import hmac
import sys

secret = sys.argv[1].encode("utf-8")
bundle_id = sys.argv[2].encode("utf-8")
print(hmac.new(secret, bundle_id, hashlib.sha256).hexdigest())
PY
)
else
  echo "⚠️ HABLA_SECRET not set. Backend auth token will be empty."
fi

mkdir -p "$OUTPUT_DIR"

cat > "$OUTPUT_FILE" <<EOF_CONFIG
import Foundation

// Auto-generated. Do not edit.
// Generated on $(date)
enum AppConfig {
    static let backendURL = "$BACKEND_URL"
    static let backendAuthToken = "$AUTH_TOKEN"
}

enum BackendRequestAuth {
    static var token: String {
        AppConfig.backendAuthToken.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func apply(to request: inout URLRequest) {
        guard !token.isEmpty else {
            return
        }
        request.setValue(token, forHTTPHeaderField: "Authorization")
    }
}
EOF_CONFIG

echo "✅ Generated $OUTPUT_FILE"
