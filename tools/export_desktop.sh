#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/godot"
BUILD_DIR="$ROOT_DIR/builds/desktop"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
TEMPLATE_DIR="${GODOT_EXPORT_TEMPLATES_DIR:-$HOME/Library/Application Support/Godot/export_templates/4.6.2.stable}"

usage() {
  cat <<'EOF'
Usage:
  tools/export_desktop.sh --check-templates
  tools/export_desktop.sh [macos|windows|linux]

Environment:
  GODOT_BIN                    Godot executable path.
  GODOT_EXPORT_TEMPLATES_DIR   Godot 4.6.2 export templates directory.
EOF
}

template_requirements() {
  cat <<EOF
macOS|$TEMPLATE_DIR/macos.zip
Windows Desktop|$TEMPLATE_DIR/windows_release_x86_64.exe
Linux|$TEMPLATE_DIR/linux_release.x86_64
EOF
}

check_templates() {
  local missing=0
  while IFS='|' read -r preset template_path; do
    if [[ ! -f "$template_path" ]]; then
      printf 'missing template for %s: %s\n' "$preset" "$template_path" >&2
      missing=1
    fi
  done < <(template_requirements)

  if [[ "$missing" -ne 0 ]]; then
    printf '\nInstall the matching Godot 4.6.2 export templates, or set GODOT_EXPORT_TEMPLATES_DIR.\n' >&2
    return 64
  fi
}

export_path_for() {
  case "$1" in
    macos)
      printf '%s/macos/SisyphusDownhill.zip' "$BUILD_DIR"
      ;;
    windows)
      printf '%s/windows/SisyphusDownhill.exe' "$BUILD_DIR"
      ;;
    linux)
      printf '%s/linux/SisyphusDownhill.x86_64' "$BUILD_DIR"
      ;;
    *)
      printf 'unknown export target: %s\n' "$1" >&2
      return 2
      ;;
  esac
}

preset_for() {
  case "$1" in
    macos)
      printf 'macOS'
      ;;
    windows)
      printf 'Windows Desktop'
      ;;
    linux)
      printf 'Linux'
      ;;
    *)
      printf 'unknown export target: %s\n' "$1" >&2
      return 2
      ;;
  esac
}

export_target() {
  local target="$1"
  local output
  local preset
  output="$(export_path_for "$target")"
  preset="$(preset_for "$target")"
  mkdir -p "$(dirname "$output")"
  "$GODOT_BIN" --headless --recovery-mode --path "$PROJECT_DIR" --export-release "$preset" "$output"
}

main() {
  local target="${1:-macos}"
  case "$target" in
    -h|--help)
      usage
      ;;
    --check-templates)
      check_templates
      ;;
    macos|windows|linux)
      check_templates
      export_target "$target"
      ;;
    *)
      usage >&2
      return 2
      ;;
  esac
}

main "$@"
