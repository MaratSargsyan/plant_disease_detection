#!/usr/bin/env bash
# One-time script to build and install the TFLite C API shared library for Linux.
# Requires: cmake, ninja-build, git, g++, python3
# Run from the project root:  bash tools/setup_tflite.sh
# Takes ~20–40 minutes on first run; subsequent runs are instant.

set -euo pipefail

BLOBS_DIR="$(dirname "$0")/../blobs"
BLOBS_DIR="$(cd "$BLOBS_DIR" && pwd)"
TFLITE_LIB="$BLOBS_DIR/libtensorflowlite_c-linux.so"

if [ -f "$TFLITE_LIB" ]; then
  echo "✓ TFLite library already present at $TFLITE_LIB"
  exit 0
fi

# ── Pre-flight checks ──────────────────────────────────────────────────────────
for tool in cmake ninja git g++ python3; do
  if ! command -v "$tool" &>/dev/null; then
    echo "✗ '$tool' not found. Install with:"
    echo "    sudo apt install cmake ninja-build git g++ python3"
    exit 1
  fi
done

mkdir -p "$BLOBS_DIR"

BUILD_DIR="$(mktemp -d /tmp/tflite_build.XXXXXX)"
echo "Working directory: $BUILD_DIR"
trap "rm -rf '$BUILD_DIR'" EXIT

# ── Shallow-clone TensorFlow (only TFLite is needed) ──────────────────────────
echo ""
echo "Cloning TensorFlow v2.14.0 (shallow)…"
git clone \
  --depth=1 \
  --branch=v2.14.0 \
  --filter=blob:none \
  --sparse \
  https://github.com/tensorflow/tensorflow.git \
  "$BUILD_DIR/tensorflow"

cd "$BUILD_DIR/tensorflow"
git sparse-checkout set tensorflow/lite third_party

# ── CMake configure ───────────────────────────────────────────────────────────
echo ""
echo "Configuring CMake…"
mkdir -p "$BUILD_DIR/cmake_build"
cmake \
  -S "$BUILD_DIR/tensorflow/tensorflow/lite" \
  -B "$BUILD_DIR/cmake_build" \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DTFLITE_C_BUILD_SHARED_LIBS=ON \
  -DTFLITE_ENABLE_GPU=OFF \
  -DTFLITE_ENABLE_XNNPACK=OFF \
  -DTFLITE_ENABLE_NNAPI=OFF

# ── Build ─────────────────────────────────────────────────────────────────────
echo ""
echo "Building libtensorflowlite_c.so (this takes a while)…"
cmake --build "$BUILD_DIR/cmake_build" --target tensorflowlite_c -j"$(nproc)"

# ── Install ───────────────────────────────────────────────────────────────────
cp "$BUILD_DIR/cmake_build/libtensorflowlite_c.so" "$TFLITE_LIB"
echo ""
echo "✓ Library installed: $TFLITE_LIB"
echo ""
echo "Now run:  flutter run -d linux"
echo "   or  :  flutter build linux"
