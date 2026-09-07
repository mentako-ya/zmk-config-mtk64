#!/bin/bash
set -e

# ==============================================================================
# mtk64ebt 直接PC接続 (BLE Split) ローカルビルドスクリプト (right_left_rev4)
# ==============================================================================

# Base directories
REPO_ROOT="/Users/tools/git/zmk-config-mtk64"
WORKSPACE="/Users/tools/git/zmk-build-workspace"
SDK_PATH="/Users/tools/zephyr-sdk-0.17.0"
SDK_DIR="${SDK_PATH}/cmake"
OUTPUT_DIR="${REPO_ROOT}/firmware"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Security quarantine fix
xattr -dr com.apple.quarantine "$SDK_PATH" 2>/dev/null || true

TARGET="${1:-all}"

build_right_direct() {
    echo "=== Building Right Central for Direct PC Connection (mtk64_R BLE, Peripherals=1) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/right_direct -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_R rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DSNIPPET="studio-rpc-usb-uart" \
      -DCONFIG_ZMK_STUDIO=y \
      -DCONFIG_ZMK_SPLIT_BLE_CENTRAL_PERIPHERALS=1
    cp "${WORKSPACE}/build/right_direct/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_R.uf2"
    echo "-> Right Central (BLE) firmware built: ${OUTPUT_DIR}/mtk64_R.uf2"
}

build_right_foot() {
    echo "=== Building Right Central for Direct PC Connection with Foot (mtk64_R_foot BLE, Peripherals=2) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/right_foot -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_R rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DSNIPPET="studio-rpc-usb-uart" \
      -DCONFIG_ZMK_STUDIO=y \
      -DCONFIG_ZMK_SPLIT_BLE_CENTRAL_PERIPHERALS=2
    cp "${WORKSPACE}/build/right_foot/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_R_foot.uf2"
    echo "-> Right Central with Foot (BLE) firmware built: ${OUTPUT_DIR}/mtk64_R_foot.uf2"
}

build_left_direct() {
    echo "=== Building Left Peripheral for Direct PC Connection (mtk64_L BLE) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/left_direct -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_L rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config"
    cp "${WORKSPACE}/build/left_direct/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_L.uf2"
    echo "-> Left Peripheral (BLE) firmware built: ${OUTPUT_DIR}/mtk64_L.uf2"
}

build_foot_direct() {
    echo "=== Building Foot Switch for Direct PC Connection (mtk64_FOOT BLE) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/foot_direct -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_FOOT rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config"
    cp "${WORKSPACE}/build/foot_direct/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_FOOT.uf2"
    echo "-> Foot Switch (BLE) firmware built: ${OUTPUT_DIR}/mtk64_FOOT.uf2"
}

build_leftball_right() {
    echo "=== Building Left-Ball Right Central (mtk64_leftball_R BLE, Peripherals=1) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/leftball_right -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_leftball_R rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DSNIPPET="studio-rpc-usb-uart" \
      -DCONFIG_ZMK_STUDIO=y \
      -DCONFIG_ZMK_SPLIT_BLE_CENTRAL_PERIPHERALS=1
    cp "${WORKSPACE}/build/leftball_right/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_R_leftball.uf2"
    echo "-> Left-Ball Right Central firmware built: ${OUTPUT_DIR}/mtk64_R_leftball.uf2"
}

build_leftball_right_foot() {
    echo "=== Building Left-Ball Right Central with Foot (mtk64_leftball_R BLE, Peripherals=2) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/leftball_right_foot -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_leftball_R rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DSNIPPET="studio-rpc-usb-uart" \
      -DCONFIG_ZMK_STUDIO=y \
      -DCONFIG_ZMK_SPLIT_BLE_CENTRAL_PERIPHERALS=2
    cp "${WORKSPACE}/build/leftball_right_foot/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_R_foot_leftball.uf2"
    echo "-> Left-Ball Right Central with Foot firmware built: ${OUTPUT_DIR}/mtk64_R_foot_leftball.uf2"
}

build_leftball_left() {
    echo "=== Building Left-Ball Left Peripheral (mtk64_leftball_L BLE) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/leftball_left -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_leftball_L rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config"
    cp "${WORKSPACE}/build/leftball_left/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_L_leftball.uf2"
    echo "-> Left-Ball Left Peripheral firmware built: ${OUTPUT_DIR}/mtk64_L_leftball.uf2"
}

build_reset() {
    echo "=== Building Settings Reset ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/reset -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="settings_reset" \
      -DZMK_CONFIG="${REPO_ROOT}/config"
    cp "${WORKSPACE}/build/reset/zephyr/zmk.uf2" "${OUTPUT_DIR}/settings_reset.uf2"
    echo "-> Settings reset firmware built: ${OUTPUT_DIR}/settings_reset.uf2"
}

case "$TARGET" in
    right|right_direct)
        build_right_direct
        ;;
    right_foot)
        build_right_foot
        ;;
    left|left_direct)
        build_left_direct
        ;;
    foot|foot_direct)
        build_foot_direct
        ;;
    leftball_right)
        build_leftball_right
        ;;
    leftball_right_foot)
        build_leftball_right_foot
        ;;
    leftball_left)
        build_leftball_left
        ;;
    leftball)
        build_leftball_right
        build_leftball_right_foot
        build_leftball_left
        ;;
    reset)
        build_reset
        ;;
    all|ALL)
        build_right_direct
        build_right_foot
        build_left_direct
        build_foot_direct
        build_leftball_right
        build_leftball_right_foot
        build_leftball_left
        build_reset
        ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Options: all, right, right_foot, left, foot, leftball, leftball_right, leftball_right_foot, leftball_left, reset"
        exit 1
        ;;
esac

package_zips() {
    echo "=== Packaging Firmware ZIPs ==="
    cd "$OUTPUT_DIR"
    
    # 1. Right + Left (Direct connection)
    if [ -f "mtk64_R.uf2" ] && [ -f "mtk64_L.uf2" ]; then
        zip -q "mtk64ebt_Right_Left.zip" mtk64_R.uf2 mtk64_L.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left.zip"
    fi

    # 2. Right + Left + Foot
    if [ -f "mtk64_R_foot.uf2" ] && [ -f "mtk64_L.uf2" ] && [ -f "mtk64_FOOT.uf2" ]; then
        mkdir -p pkg_foot
        cp mtk64_R_foot.uf2 pkg_foot/mtk64_R.uf2
        cp mtk64_L.uf2 pkg_foot/
        cp mtk64_FOOT.uf2 pkg_foot/
        cp settings_reset.uf2 pkg_foot/ 2>/dev/null || true
        (cd pkg_foot && zip -q "../mtk64ebt_Right_Left_Foot.zip" *.uf2)
        rm -rf pkg_foot
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Foot.zip"
    fi

    # 3. Right + Left (Left-ball variation)
    if [ -f "mtk64_R_leftball.uf2" ] && [ -f "mtk64_L_leftball.uf2" ]; then
        zip -q "mtk64ebt_Right_Left_leftball.zip" mtk64_R_leftball.uf2 mtk64_L_leftball.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_leftball.zip"
    fi

    # 4. Right + Left + Foot (Left-ball variation)
    R_FOOT_LB=""
    if [ -f "mtk64_R_foot_leftball.uf2" ]; then
        R_FOOT_LB="mtk64_R_foot_leftball.uf2"
    elif [ -f "mtk64_R_leftball_foot.uf2" ]; then
        R_FOOT_LB="mtk64_R_leftball_foot.uf2"
    fi

    if [ -n "$R_FOOT_LB" ] && [ -f "mtk64_L_leftball.uf2" ] && [ -f "mtk64_FOOT.uf2" ]; then
        mkdir -p pkg_foot_leftball
        cp "$R_FOOT_LB" pkg_foot_leftball/mtk64_R_leftball.uf2
        cp mtk64_L_leftball.uf2 pkg_foot_leftball/
        cp mtk64_FOOT.uf2 pkg_foot_leftball/
        cp settings_reset.uf2 pkg_foot_leftball/ 2>/dev/null || true
        (cd pkg_foot_leftball && zip -q "../mtk64ebt_Right_Left_Foot_leftball.zip" *.uf2)
        rm -rf pkg_foot_leftball
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Foot_leftball.zip"
    fi
}

package_zips

echo "=== Build Complete ==="
