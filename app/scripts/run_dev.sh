#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# run_dev.sh — Run the Flutter app with all environment keys
#
# Usage (from repo root):
#   bash app/scripts/run_dev.sh
#   bash app/scripts/run_dev.sh --release
#   bash app/scripts/run_dev.sh -d "iPhone 15"
#
# All extra arguments are forwarded to `flutter run`.
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# Resolve repo root (one level above this script's parent)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

# ── Verify .env exists ────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
  echo ""
  echo "  ERROR: .env file not found at $ENV_FILE"
  echo "  Run:  cp .env.example .env  then fill in your keys."
  echo ""
  exit 1
fi

# ── Load .env (skip comments and blank lines) ─────────────────
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip comments and empty lines
  if [[ ! "$line" =~ ^\s*# ]] && [[ ! "$line" =~ ^\s*$ ]]; then
    export "$line"
  fi
done < "$ENV_FILE"

# ── Validate required variables ───────────────────────────────
required=(
  SUPABASE_URL
  SUPABASE_ANON_KEY
  CLAUDE_API_KEY
  GOOGLE_PLACES_API_KEY
  CLIMATIQ_API_KEY
)

missing=()
for var in "${required[@]}"; do
  value="${!var:-}"
  if [ -z "$value" ] || [[ "$value" == *"your_"* ]]; then
    missing+=("$var")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  echo ""
  echo "  ERROR: The following variables are missing or still have placeholder values:"
  for var in "${missing[@]}"; do
    echo "    - $var"
  done
  echo ""
  echo "  Edit .env and fill in real values. See docs/SETUP.md for where to find each key."
  echo ""
  exit 1
fi

# ── Run Flutter ───────────────────────────────────────────────
echo "  Starting AllTogether (dev)..."
echo ""

cd "$REPO_ROOT/app"

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  "$@"
