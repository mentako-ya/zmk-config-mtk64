#!/bin/bash
set -e

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

build_left() {
    echo "=== Building Left (mtk64_L) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/left -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_L rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config"
    cp "${WORKSPACE}/build/left/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_L.uf2"
    echo "-> Left firmware built: ${OUTPUT_DIR}/mtk64_L.uf2"
}

build_right() {
    echo "=== Building Right Peripheral (mtk64_R ESB) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/right -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_R rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config"
    cp "${WORKSPACE}/build/right/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_R.uf2"
    cp "${WORKSPACE}/build/right/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_R_dongle.uf2"
    echo "-> Right firmware built: ${OUTPUT_DIR}/mtk64_R.uf2 & mtk64_R_dongle.uf2"
}

build_right_debug() {
    echo "=== Building Right Peripheral with USB Logging (mtk64_R_debug) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/right_debug -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_R rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DCONFIG_ZMK_USB_LOGGING=y \
      -DCONFIG_INPUT_LOG_LEVEL_DBG=y
    cp "${WORKSPACE}/build/right_debug/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_R_debug.uf2"
    echo "-> Right debug firmware built: ${OUTPUT_DIR}/mtk64_R_debug.uf2"
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

build_dongle_debug() {
    echo "=== Building Dongle with Display and USB Logging (mtk64_DONGLE_debug) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/dongle_debug -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_DONGLE rgbled_adapter dongle_display" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DCONFIG_ZMK_USB_LOGGING=y \
      -DCONFIG_ZMK_LOGGING_MINIMAL=y
    cp "${WORKSPACE}/build/dongle_debug/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_DONGLE_debug.uf2"
    echo "-> Dongle debug firmware built: ${OUTPUT_DIR}/mtk64_DONGLE_debug.uf2"
}

build_dongle_nodisplay() {
    echo "=== Building Dongle without Display (mtk64_DONGLE) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/dongle -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_DONGLE rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DCONFIG_ZMK_STUDIO=y \
      -DSNIPPET="studio-rpc-usb-uart"
    cp "${WORKSPACE}/build/dongle/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_DONGLE.uf2"
    echo "-> Dongle firmware built: ${OUTPUT_DIR}/mtk64_DONGLE.uf2"
}

build_dongle() {
    echo "=== Building Dongle with Display (mtk64_DONGLE + OLED) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/dongle_display -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_DONGLE rgbled_adapter dongle_display" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DCONFIG_ZMK_STUDIO=y \
      -DSNIPPET="studio-rpc-usb-uart"
    cp "${WORKSPACE}/build/dongle_display/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_DONGLE_display.uf2"
    echo "-> Dongle display firmware built: ${OUTPUT_DIR}/mtk64_DONGLE_display.uf2"
}

build_leftball_l() {
    echo "=== Building Left-ball Left Peripheral (mtk64_leftball_L with trackball) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/leftball_l -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_leftball_L rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config"
    cp "${WORKSPACE}/build/leftball_l/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_L_leftball.uf2"
    echo "-> Left-ball Left firmware built: ${OUTPUT_DIR}/mtk64_L_leftball.uf2"
}

build_leftball_r() {
    echo "=== Building Left-ball Right Peripheral (mtk64_leftball_R with encoders) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/leftball_r -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_leftball_R rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n
    cp "${WORKSPACE}/build/leftball_r/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_R_leftball.uf2"
    echo "-> Left-ball Right firmware built: ${OUTPUT_DIR}/mtk64_R_leftball.uf2"
}

build_foot() {
    echo "=== Building Foot Switch (mtk64_FOOT) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/foot -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_FOOT rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config"
    cp "${WORKSPACE}/build/foot/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_FOOT.uf2"
    echo "-> Foot switch firmware built: ${OUTPUT_DIR}/mtk64_FOOT.uf2"
}

case "$TARGET" in
    right_debug|r_debug|debug_right)
        build_right_debug
        ;;
    dongle_debug|d_debug|debug_dongle)
        build_dongle_debug
        ;;
    right|R|r)
        build_right
        ;;
    left|L|l)
        build_left
        ;;
    dongle|DONGLE)
        build_dongle
        build_right
        build_left
        ;;
    dongle_nodisplay)
        build_dongle_nodisplay
        build_right
        build_left
        ;;
    leftball|left_ball)
        build_leftball_l
        build_leftball_r
        build_dongle
        ;;
    foot|FOOT)
        build_foot
        ;;
    reset)
        build_reset
        ;;
    all|ALL)
        build_right
        build_left
        build_dongle
        build_dongle_nodisplay
        build_leftball_l
        build_leftball_r
        build_foot
        build_reset
        ;;
    *)
        echo "Unknown target: $TARGET (Options: all, right, right_debug, left, dongle, dongle_nodisplay, leftball, foot, reset)"
        exit 1
        ;;
esac

package_zips() {
    echo "=== Packaging Firmware ZIPs (All 6 Configurations) ==="
    cd "$OUTPUT_DIR"
    
    # 1. Right + Left (Direct connection)
    if [ -f "mtk64_R.uf2" ] && [ -f "mtk64_L.uf2" ]; then
        zip -q "mtk64ebt_Right_Left.zip" mtk64_R.uf2 mtk64_L.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left.zip"
    fi

    # 2. Right + Left + Foot
    if [ -f "mtk64_R.uf2" ] && [ -f "mtk64_L.uf2" ] && [ -f "mtk64_FOOT.uf2" ]; then
        zip -q "mtk64ebt_Right_Left_Foot.zip" mtk64_R.uf2 mtk64_L.uf2 mtk64_FOOT.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Foot.zip"
    fi

    # 3. Right + Left + Dongle (no OLED)
    if [ -f "mtk64_DONGLE.uf2" ] && [ -f "mtk64_R_dongle.uf2" ]; then
        zip -q "mtk64ebt_Right_Left_Dongle.zip" mtk64_DONGLE.uf2 mtk64_R_dongle.uf2 mtk64_L.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle.zip"
    fi

    # 4. Right + Left + Dongle (with OLED display)
    if [ -f "mtk64_DONGLE_display.uf2" ] && [ -f "mtk64_R_dongle.uf2" ]; then
        zip -q "mtk64ebt_Right_Left_Dongle_display.zip" mtk64_DONGLE_display.uf2 mtk64_R_dongle.uf2 mtk64_L.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle_display.zip"
    fi

    # 5. Right + Left + Dongle (with OLED) + Foot
    if [ -f "mtk64_DONGLE_display.uf2" ] && [ -f "mtk64_R_dongle.uf2" ] && [ -f "mtk64_FOOT.uf2" ]; then
        zip -q "mtk64ebt_Right_Left_Dongle_disp_foot.zip" mtk64_DONGLE_display.uf2 mtk64_R_dongle.uf2 mtk64_L.uf2 mtk64_FOOT.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle_disp_foot.zip"
    fi

    # 6. Left-ball + Right-encoder + Dongle (with OLED)
    if [ -f "mtk64_DONGLE_display.uf2" ] && [ -f "mtk64_L_leftball.uf2" ] && [ -f "mtk64_R_leftball.uf2" ]; then
        zip -q "mtk64ebt_Right_Left_Dongle_disp_leftball.zip" mtk64_DONGLE_display.uf2 mtk64_L_leftball.uf2 mtk64_R_leftball.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle_disp_leftball.zip"
    fi

    # 7. Complete package containing all firmware
    zip -q "mtk64ebt_All.zip" *.uf2 2>/dev/null || true
    echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_All.zip"
}

package_zips

echo "=== Build Complete ==="
