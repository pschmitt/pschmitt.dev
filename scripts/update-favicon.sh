#!/usr/bin/env bash

set -euo pipefail

DEFAULT_EMAIL="philipp@schmitt.co"
: "${PNG_SIZE:=256}"
: "${ICON_SIZES:=256,128,64,32,16}"
: "${PNG_PATH:=favicon.png}"
: "${ICO_PATH:=favicon.ico}"

usage() {
  cat <<EOF
Usage: scripts/update-favicon.sh [options] [gravatar-email|md5-hash]

Downloads a Gravatar image and regenerates favicon.png + favicon.ico.
If no argument is provided, the default email for the configured profile is used.
Options:
  --email EMAIL          Use the provided email address (hash is computed automatically)
  --hash HASH            Use a raw MD5 hash directly
  --size PX              PNG download size (default: ${PNG_SIZE})
  --icon-sizes LIST      Comma-separated ICO sizes (default: ${ICON_SIZES})
  --png-path PATH        Output path for favicon.png (default: ${PNG_PATH})
  --ico-path PATH        Output path for favicon.ico (default: ${ICO_PATH})
  -h, --help             Show this help message
EOF
}

normalize_email() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'
}

email_to_hash() {
  local normalized_email="$1"
  printf '%s' "$normalized_email" | md5sum | awk '{print $1}'
}

download_png() {
  local hash="$1"
  local png_size="$2"
  local png_path="$3"
  local url="https://www.gravatar.com/avatar/${hash}?s=${png_size}"
  echo "Downloading favicon source from ${url}"
  curl -fsSL "$url" -o "$png_path"
}

ensure_magick() {
  local ico_path="$1"
  if ! command -v magick >/dev/null 2>&1
  then
    echo "ImageMagick 7 (magick) is required to build ${ico_path}." >&2
    return 1
  fi
}

build_ico() {
  local png_path="$1"
  local icon_sizes="$2"
  local ico_path="$3"
  magick "$png_path" -define icon:auto-resize="${icon_sizes}" "$ico_path"
}

resolve_hash() {
  local input="$1"
  local hash_override="$2"
  local output="$3"
  local hash_value=""

  if [[ -n "$hash_override" ]]
  then
    hash_value="$hash_override"
  elif [[ "$input" == *"@"* ]]
  then
    local normalized_email
    normalized_email="$(normalize_email "$input")"
    hash_value="$(email_to_hash "$normalized_email")"
    echo "Email ${normalized_email} -> ${hash_value}"
  else
    hash_value="$input"
  fi

  printf -v "$output" '%s' "$hash_value"
}

main() {
  local email="$DEFAULT_EMAIL"
  local hash_override=""
  local positional_input=""
  local png_size="$PNG_SIZE"
  local icon_sizes="$ICON_SIZES"
  local png_path="$PNG_PATH"
  local ico_path="$ICO_PATH"

  while [[ $# -gt 0 ]]
  do
    case "$1" in
      --email)
        if [[ $# -lt 2 ]]
        then
          echo "Missing value for --email" >&2
          usage
          return 2
        fi
        email="$2"
        shift 2
        ;;
      --hash)
        if [[ $# -lt 2 ]]
        then
          echo "Missing value for --hash" >&2
          usage
          return 2
        fi
        hash_override="$2"
        shift 2
        ;;
      --size)
        if [[ $# -lt 2 ]]
        then
          echo "Missing value for --size" >&2
          usage
          return 2
        fi
        png_size="$2"
        shift 2
        ;;
      --icon-sizes)
        if [[ $# -lt 2 ]]
        then
          echo "Missing value for --icon-sizes" >&2
          usage
          return 2
        fi
        icon_sizes="$2"
        shift 2
        ;;
      --png-path)
        if [[ $# -lt 2 ]]
        then
          echo "Missing value for --png-path" >&2
          usage
          return 2
        fi
        png_path="$2"
        shift 2
        ;;
      --ico-path)
        if [[ $# -lt 2 ]]
        then
          echo "Missing value for --ico-path" >&2
          usage
          return 2
        fi
        ico_path="$2"
        shift 2
        ;;
      -h|--help)
        usage
        return 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "Unknown option: $1" >&2
        usage
        return 2
        ;;
      *)
        if [[ -n "$positional_input" ]]
        then
          echo "Unexpected argument: $1" >&2
          usage
          return 2
        fi
        positional_input="$1"
        shift
        ;;
    esac
  done

  if [[ $# -gt 0 ]]
  then
    echo "Unexpected extra arguments: $*" >&2
    usage
    return 2
  fi

  local input="${positional_input:-$email}"
  local hash_input=""

  if ! resolve_hash "$input" "$hash_override" hash_input
  then
    return 1
  fi

  if ! download_png "$hash_input" "$png_size" "$png_path"
  then
    return 1
  fi

  if ! ensure_magick "$ico_path"
  then
    return 1
  fi

  if ! build_ico "$png_path" "$icon_sizes" "$ico_path"
  then
    return 1
  fi

  echo "Updated $png_path and $ico_path"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]
then
  main "$@"
fi
