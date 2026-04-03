#!/bin/bash
set -euo pipefail

KVER=$(uname -r)
MOD_DIR="/lib/modules/${KVER}"
KBUILD="${MOD_DIR}/build"
WORK_DIR=$(mktemp -d)

echo "=== SDCA Class Module Fix ==="
echo "Kernel: ${KVER}"
echo "Working dir: ${WORK_DIR}"
echo ""

# Step 1: Check if modules already exist and are loadable
echo "[1/6] Checking existing modules..."

SDCA_CLASS="${MOD_DIR}/kernel/sound/soc/sdca/snd-soc-sdca-class.ko.zst"
SDCA_CLASS_FUNC="${MOD_DIR}/kernel/sound/soc/sdca/snd-soc-sdca-class-function.ko.zst"

if [ -f "$SDCA_CLASS" ] && [ -f "$SDCA_CLASS_FUNC" ]; then
    echo "Modules already exist:"
    echo "  $SDCA_CLASS"
    echo "  $SDCA_CLASS_FUNC"
    echo ""
    echo "Checking if they load..."
    if modprobe -n snd_soc_sdca_class 2>/dev/null; then
        echo "snd_soc_sdca_class can be loaded."
        if lsmod | grep -q snd_soc_sdca_class; then
            echo "Already loaded! Nothing to do."
            rm -rf "$WORK_DIR"
            exit 0
        else
            echo "Not currently loaded. Try: sudo modprobe snd_soc_sdca_class"
            rm -rf "$WORK_DIR"
            exit 0
        fi
    else
        echo "Module exists but won't load — rebuilding."
    fi
else
    echo "Modules missing — need to build."
fi

# Step 2: Verify build prerequisites
echo ""
echo "[2/6] Checking prerequisites..."

if [ ! -d "$KBUILD" ]; then
    echo "ERROR: Kernel build dir not found at ${KBUILD}"
    echo "Install linux-mainline-headers first."
    rm -rf "$WORK_DIR"
    exit 1
fi

if ! command -v make &>/dev/null; then
    echo "ERROR: make not found. Install base-devel."
    rm -rf "$WORK_DIR"
    exit 1
fi

# Step 3: Determine kernel source tag and download SDCA source files
echo ""
echo "[3/6] Downloading SDCA source files..."

# Extract version to determine the git tag
# 7.0.0-rc6-1-mainline -> v7.0-rc6
MAJOR=$(echo "$KVER" | cut -d. -f1)
MINOR=$(echo "$KVER" | cut -d. -f2)
RC=$(echo "$KVER" | grep -oP 'rc\d+' || true)

if [ -n "$RC" ]; then
    TAG="v${MAJOR}.${MINOR}-${RC}"
else
    TAG="v${MAJOR}.${MINOR}"
fi

echo "Kernel tag: ${TAG}"

BASE_URL="https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/sound/soc/sdca"

# Files needed for snd-soc-sdca-class and snd-soc-sdca-class-function
FILES=(
    "sdca_class.c"
    "sdca_class_function.c"
    "Makefile"
)

mkdir -p "${WORK_DIR}/sdca"

DOWNLOAD_FAILED=0
for f in "${FILES[@]}"; do
    echo "  Downloading ${f}..."
    if ! curl -sL -f "${BASE_URL}/${f}?h=${TAG}" -o "${WORK_DIR}/sdca/${f}"; then
        echo "  WARNING: Failed to download ${f} (may not exist in ${TAG})"
        DOWNLOAD_FAILED=1
    fi
done

# Also grab any header files from the sdca dir
for f in $(curl -sL "${BASE_URL}/?h=${TAG}" | grep -oP '[a-z_]+\.h' | sort -u); do
    echo "  Downloading ${f}..."
    curl -sL -f "${BASE_URL}/${f}?h=${TAG}" -o "${WORK_DIR}/sdca/${f}" 2>/dev/null || true
done

if [ ! -f "${WORK_DIR}/sdca/sdca_class.c" ]; then
    echo "ERROR: Could not download sdca_class.c — cannot continue."
    rm -rf "$WORK_DIR"
    exit 1
fi

echo "Source files downloaded."

# Step 4: Create a Kbuild file for out-of-tree build
echo ""
echo "[4/6] Preparing build..."

cat > "${WORK_DIR}/sdca/Kbuild" << 'EOF'
obj-m += snd-soc-sdca-class.o
snd-soc-sdca-class-y := sdca_class.o

obj-m += snd-soc-sdca-class-function.o
snd-soc-sdca-class-function-y := sdca_class_function.o
EOF

# Step 5: Build
echo ""
echo "[5/6] Building modules..."

if ! make -C "$KBUILD" M="${WORK_DIR}/sdca" modules 2>&1; then
    echo ""
    echo "Build failed. This may need adjustments to the Kbuild file."
    echo "Source files are in: ${WORK_DIR}/sdca/"
    exit 1
fi

echo "Build successful!"

# Step 6: Install
echo ""
echo "[6/6] Installing modules..."

DEST="${MOD_DIR}/kernel/sound/soc/sdca"
echo "Installing to: ${DEST}"

for ko in "${WORK_DIR}/sdca/"snd-soc-sdca-class*.ko; do
    if [ -f "$ko" ]; then
        name=$(basename "$ko")
        echo "  Compressing and installing ${name}..."
        zstd -f -q "$ko" -o "${DEST}/${name}.zst"
    fi
done

echo "Running depmod..."
depmod -a "$KVER"

echo ""
echo "=== Done! ==="
echo ""
echo "Load the modules with:"
echo "  sudo modprobe snd_soc_sdca_class"
echo ""
echo "Then reboot (or reload the audio stack) to see if the sound card registers."
echo "Working dir preserved at: ${WORK_DIR}"
