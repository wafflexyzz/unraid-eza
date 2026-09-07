#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${1:-$(sed -n 's/.*<!ENTITY version[[:space:]]*"\([^"]*\)".*/\1/p' "$ROOT_DIR/unraid-eza.plg" | head -n 1)}"
EZA_VERSION="${VERSION#v}"
IMAGE_PLATFORM="${DOCKER_DEFAULT_PLATFORM:-linux/amd64}"
CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-2}"
TARGET="x86_64-unknown-linux-gnu"
BUILD_DIR="$ROOT_DIR/.build"
PACKAGE_DIR="$BUILD_DIR/package"
OUTPUT_DIR="$ROOT_DIR/dist"
PACKAGE="$OUTPUT_DIR/unraid-eza-${VERSION}.txz"

if [[ -z "$VERSION" ]]; then
    echo "Unable to determine the plugin version. Pass it explicitly, for example: ./build.sh v0.23.5" >&2
    exit 1
fi

if [[ ! -d "$ROOT_DIR/usr" ]]; then
    echo "Plugin payload directory not found: $ROOT_DIR/usr" >&2
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required to build the x86_64 Linux binary and Slackware package." >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Docker is installed but its daemon is not running. Start Docker Desktop (or your Docker runtime) and retry." >&2
    exit 1
fi

if [[ ! -d "$ROOT_DIR/eza/.git" && ! -f "$ROOT_DIR/eza/.git" ]]; then
    git -C "$ROOT_DIR" submodule update --init --recursive
fi

git -C "$ROOT_DIR/eza" fetch --tags --quiet
git -C "$ROOT_DIR/eza" checkout --quiet "tags/v${EZA_VERSION}"

rm -rf "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR" "$PACKAGE_DIR/usr/sbin"

docker run --rm --platform "$IMAGE_PLATFORM" \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp -e CARGO_HOME=/tmp/cargo -e CARGO_BUILD_JOBS="$CARGO_BUILD_JOBS" \
    -v "$ROOT_DIR:/workspace" \
    -w /workspace/eza \
    rust:latest \
    cargo build --release --target "$TARGET" --no-default-features

docker run --rm --platform "$IMAGE_PLATFORM" \
    -v "$ROOT_DIR:/workspace" \
    -w /tmp \
    rust:latest \
    bash -c '
        set -e
        mkdir -p /tmp/verify
        touch /tmp/verify/verify
        /workspace/eza/target/'"$TARGET"'/release/eza --long >/tmp/verify/output
        test "$(wc -l </tmp/verify/output)" -eq 1
    '

cp "$ROOT_DIR/eza/target/$TARGET/release/eza" "$PACKAGE_DIR/usr/sbin/eza"
cp -R "$ROOT_DIR/usr/." "$PACKAGE_DIR/usr/"
chmod +x "$PACKAGE_DIR/usr/sbin/eza"

docker run --rm --platform "$IMAGE_PLATFORM" \
    -v "$ROOT_DIR:/workspace" \
    -w /workspace/.build/package \
    vbatts/slackware:15 \
    makepkg -l y -c y "/workspace/dist/unraid-eza-${VERSION}.txz"

if command -v md5sum >/dev/null 2>&1; then
    checksum="$(md5sum "$PACKAGE" | cut -d ' ' -f 1)"
else
    checksum="$(md5 -r "$PACKAGE" | cut -d ' ' -f 1)"
fi
printf '%s  %s\n' "$checksum" "$(basename "$PACKAGE")" > "$OUTPUT_DIR/md5sum.txt"
echo "Built $PACKAGE"
echo "MD5: $checksum"
