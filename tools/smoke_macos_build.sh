#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP_PATH="${1:-$ROOT_DIR/builds/desktop/macos/SisyphusDownhill.zip}"

if [[ ! -f "$ZIP_PATH" ]]; then
  printf 'missing macOS build zip: %s\n' "$ZIP_PATH" >&2
  printf 'run: %s/tools/export_desktop.sh macos\n' "$ROOT_DIR" >&2
  exit 66
fi

RUN_DIR="$(mktemp -d /private/tmp/sisyphus-macos-smoke.XXXXXX)"
unzip -oq "$ZIP_PATH" -d "$RUN_DIR"

APP_PATH="$(find "$RUN_DIR" -maxdepth 1 -name '*.app' -type d | head -1)"
if [[ -z "$APP_PATH" ]]; then
  printf 'no .app bundle found in %s\n' "$ZIP_PATH" >&2
  exit 67
fi

APP_NAME="$(basename "$APP_PATH" .app)"
APP_BIN="$APP_PATH/Contents/MacOS/$APP_NAME"
if [[ ! -x "$APP_BIN" ]]; then
  printf 'app executable not found or not executable: %s\n' "$APP_BIN" >&2
  exit 68
fi

LOG_PATH="$RUN_DIR/sisyphus-exported-run.log"
"$APP_BIN" --headless --log-file "$LOG_PATH" --quit-after 120

printf 'macOS build smoke passed: %s\n' "$APP_PATH"
printf 'log: %s\n' "$LOG_PATH"
