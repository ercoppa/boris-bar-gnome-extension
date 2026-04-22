#!/usr/bin/env bash
set -euo pipefail

DMG_URL="https://github.com/andrearicciotti1/boris-bar/releases/download/v1.0/BorisBar-1.0.dmg"
TARGET_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/boris-bar/builtin"

usage() {
    cat <<'EOF'
Usage: tools/import-audio-from-dmg.sh [DMG_URL]

Downloads the original Boris Bar macOS release DMG, extracts bundled audio
clips, and installs them into:

  ~/.local/share/boris-bar/builtin

Override the source DMG by passing a different URL as the first argument.

Requirements:
  - curl
  - one of: 7z, 7zz, bsdtar, hdiutil
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

SOURCE_URL="${1:-$DMG_URL}"

need_cmd() {
    command -v "$1" >/dev/null 2>&1
}

if ! need_cmd curl; then
    echo "error: curl is required" >&2
    exit 1
fi

extract_dmg() {
    local dmg_path="$1"
    local extract_dir="$2"

    if need_cmd 7z; then
        7z x -y -o"$extract_dir" "$dmg_path" >/dev/null
        return
    fi

    if need_cmd 7zz; then
        7zz x -y -o"$extract_dir" "$dmg_path" >/dev/null
        return
    fi

    if need_cmd bsdtar; then
        bsdtar -xf "$dmg_path" -C "$extract_dir"
        return
    fi

    if need_cmd hdiutil; then
        local mount_dir
        mount_dir="$extract_dir/mount"
        mkdir -p "$mount_dir"
        hdiutil attach "$dmg_path" -mountpoint "$mount_dir" -nobrowse -quiet
        cp -R "$mount_dir"/. "$extract_dir"/
        hdiutil detach "$mount_dir" -quiet
        return
    fi

    echo "error: install one of 7z, 7zz, bsdtar, or hdiutil to extract the DMG" >&2
    exit 1
}

copy_audio_files() {
    local source_dir="$1"
    local target_dir="$2"
    local copied=0

    mkdir -p "$target_dir"

    while IFS= read -r -d '' file; do
        cp "$file" "$target_dir/"
        copied=$((copied + 1))
    done < <(find "$source_dir" -type f \( \
        -iname '*.mp3' -o \
        -iname '*.mp4' -o \
        -iname '*.m4a' -o \
        -iname '*.wav' -o \
        -iname '*.aiff' -o \
        -iname '*.aif' -o \
        -iname '*.caf' -o \
        -iname '*.ogg' \
    \) -print0)

    if [[ "$copied" -eq 0 ]]; then
        echo "error: no audio clips were found in the extracted DMG" >&2
        exit 1
    fi

    echo "Imported $copied audio clips into $target_dir"
}

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

dmg_path="$work_dir/BorisBar.dmg"
extract_dir="$work_dir/extracted"

mkdir -p "$extract_dir"

echo "Downloading $SOURCE_URL"
curl -L --fail --output "$dmg_path" "$SOURCE_URL"

echo "Extracting DMG"
extract_dmg "$dmg_path" "$extract_dir"

echo "Installing audio clips into $TARGET_DIR"
copy_audio_files "$extract_dir" "$TARGET_DIR"