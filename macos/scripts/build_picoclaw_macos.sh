#!/bin/sh
set -e

if [ "${PICOCLAW_SKIP_BUILD:-0}" = "1" ]; then
  echo "[picoclaw] PICOCLAW_SKIP_BUILD=1, skip building picoclaw"
  exit 0
fi

REPO_URL="${PICOCLAW_GIT_URL:-https://github.com/sipeed/picoclaw.git}"
REPO_REF="${PICOCLAW_GIT_REF:-main}"
PROJECT_DIR_ABS="${PROJECT_DIR:-$(pwd)}"
SRC_DIR="${PICOCLAW_SOURCE_DIR:-$PROJECT_DIR_ABS/.picoclaw-src}"
BIN_NAME="picoclaw"

if ! command -v git >/dev/null 2>&1; then
  echo "error: git is required to build picoclaw" >&2
  exit 1
fi

if ! command -v go >/dev/null 2>&1; then
  echo "error: go is required to build picoclaw" >&2
  exit 1
fi

mkdir -p "$SRC_DIR"

if [ ! -d "$SRC_DIR/.git" ]; then
  echo "[picoclaw] cloning $REPO_URL to $SRC_DIR"
  rm -rf "$SRC_DIR"
  git clone --depth 1 --branch "$REPO_REF" "$REPO_URL" "$SRC_DIR"
else
  echo "[picoclaw] updating repo at $SRC_DIR"
  git -C "$SRC_DIR" fetch --depth 1 origin "$REPO_REF"
  git -C "$SRC_DIR" reset --hard FETCH_HEAD
fi

if [ -d "$SRC_DIR/cmd/picoclaw" ]; then
  BUILD_DIR="$SRC_DIR/cmd/picoclaw"
else
  BUILD_DIR="$SRC_DIR"
fi

ONBOARD_DIR="$SRC_DIR/cmd/picoclaw/internal/onboard"
ROOT_WORKSPACE_DIR="$SRC_DIR/workspace"
ONBOARD_WORKSPACE_DIR="$ONBOARD_DIR/workspace"

if [ -d "$ONBOARD_DIR" ] && [ -d "$ROOT_WORKSPACE_DIR" ] && [ ! -d "$ONBOARD_WORKSPACE_DIR" ]; then
  echo "[picoclaw] preparing onboard workspace embed files"
  cp -R "$ROOT_WORKSPACE_DIR" "$ONBOARD_WORKSPACE_DIR"
fi

BUILD_OUTPUT_DIR="${DERIVED_FILE_DIR:-$PROJECT_DIR_ABS/.build}/picoclaw"
mkdir -p "$BUILD_OUTPUT_DIR"
BUILD_OUTPUT="$BUILD_OUTPUT_DIR/$BIN_NAME"
GO_ARCH="$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')"

echo "[picoclaw] building in $BUILD_DIR (GOARCH=$GO_ARCH)"
(
  cd "$BUILD_DIR"
  CGO_ENABLED=0 GOOS=darwin GOARCH="$GO_ARCH" \
    go build -o "$BUILD_OUTPUT" .
)

if [ -n "${TARGET_BUILD_DIR:-}" ] && [ -n "${FULL_PRODUCT_NAME:-}" ]; then
  APP_BIN_DIR="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME/Contents/MacOS"
  mkdir -p "$APP_BIN_DIR"
  cp "$BUILD_OUTPUT" "$APP_BIN_DIR/$BIN_NAME"
  chmod +x "$APP_BIN_DIR/$BIN_NAME"
  echo "[picoclaw] bundled to $APP_BIN_DIR/$BIN_NAME"
else
  echo "[picoclaw] TARGET_BUILD_DIR/FULL_PRODUCT_NAME missing, skip app bundle copy"
fi
