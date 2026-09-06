#!/bin/bash
set -e

# ==============================================================================
# mtk64ebt ローカルビルドスクリプト (build.sh)
# ==============================================================================
# 同一シールド定義を用い、引数（cmake-args）によって動的に
# 「直接PC接続（BLE Central/Peripheral）」と「ドングル接続（1000Hz ESB Peripheral）」
# を作り分けます。
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

# ------------------------------------------------------------------------------
# 1. 直接PC接続構成 (BLE Central on Right)
# ------------------------------------------------------------------------------
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
      -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=y \
      -DCONFIG_ZMK_BLE=y \
      -DCONFIG_ZMK_SPLIT_BLE=y \
      -DCONFIG_ZMK_SPLIT_ESB=n \
      -DCONFIG_NRF_SECURITY=n \
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
      -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=y \
      -DCONFIG_ZMK_BLE=y \
      -DCONFIG_ZMK_SPLIT_BLE=y \
      -DCONFIG_ZMK_SPLIT_ESB=n \
      -DCONFIG_NRF_SECURITY=n \
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
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n \
      -DCONFIG_ZMK_BLE=y \
      -DCONFIG_ZMK_SPLIT_BLE=y \
      -DCONFIG_ZMK_SPLIT_ESB=n \
      -DCONFIG_NRF_SECURITY=n
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
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n \
      -DCONFIG_ZMK_BLE=y \
      -DCONFIG_ZMK_SPLIT_BLE=y \
      -DCONFIG_ZMK_SPLIT_ESB=n \
      -DCONFIG_NRF_SECURITY=n
    cp "${WORKSPACE}/build/foot_direct/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_FOOT.uf2"
    echo "-> Foot Switch (BLE) firmware built: ${OUTPUT_DIR}/mtk64_FOOT.uf2"
}

# ------------------------------------------------------------------------------
# 2. ドングル接続構成 (ESB Central on Dongle, 1000Hz Ultra Low Latency)
# ------------------------------------------------------------------------------
build_dongle() {
    echo "=== Building Dongle with Display (mtk64_DONGLE + OLED Central) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/dongle_display -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_DONGLE rgbled_adapter dongle_display" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DSNIPPET="studio-rpc-usb-uart" \
      -DCONFIG_ZMK_STUDIO=y
    cp "${WORKSPACE}/build/dongle_display/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_DONGLE_display.uf2"
    echo "-> Dongle display firmware built: ${OUTPUT_DIR}/mtk64_DONGLE_display.uf2"
}

build_dongle_nodisplay() {
    echo "=== Building Dongle without Display (mtk64_DONGLE Central) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/dongle -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_DONGLE rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DSNIPPET="studio-rpc-usb-uart" \
      -DCONFIG_ZMK_STUDIO=y
    cp "${WORKSPACE}/build/dongle/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_DONGLE.uf2"
    echo "-> Dongle firmware built: ${OUTPUT_DIR}/mtk64_DONGLE.uf2"
}

build_right_dongle() {
    echo "=== Building Right Peripheral for Dongle (mtk64_R 1000Hz ESB ID:2) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/right_dongle -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_R rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n \
      -DCONFIG_ZMK_BLE=n \
      -DCONFIG_ZMK_SPLIT_BLE=n \
      -DCONFIG_ZMK_SPLIT_ESB=y \
      -DCONFIG_ZMK_SPLIT_ESB_PERIPHERAL_ID=2
    cp "${WORKSPACE}/build/right_dongle/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_R_dongle.uf2"
    echo "-> Right ESB Peripheral firmware built: ${OUTPUT_DIR}/mtk64_R_dongle.uf2"
}

build_left_dongle() {
    echo "=== Building Left Peripheral for Dongle (mtk64_L 1000Hz ESB ID:1) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/left_dongle -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_L rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n \
      -DCONFIG_ZMK_BLE=n \
      -DCONFIG_ZMK_SPLIT_BLE=n \
      -DCONFIG_ZMK_SPLIT_ESB=y \
      -DCONFIG_ZMK_SPLIT_ESB_PERIPHERAL_ID=1
    cp "${WORKSPACE}/build/left_dongle/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_L_dongle.uf2"
    echo "-> Left ESB Peripheral firmware built: ${OUTPUT_DIR}/mtk64_L_dongle.uf2"
}

build_foot_dongle() {
    echo "=== Building Foot Switch for Dongle (mtk64_FOOT 1000Hz ESB ID:3) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/foot_dongle -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_FOOT rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n \
      -DCONFIG_ZMK_BLE=n \
      -DCONFIG_ZMK_SPLIT_BLE=n \
      -DCONFIG_ZMK_SPLIT_ESB=y \
      -DCONFIG_ZMK_SPLIT_ESB_PERIPHERAL_ID=3
    cp "${WORKSPACE}/build/foot_dongle/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_FOOT_dongle.uf2"
    echo "-> Foot Switch ESB Peripheral firmware built: ${OUTPUT_DIR}/mtk64_FOOT_dongle.uf2"
}

# ------------------------------------------------------------------------------
# 3. 変則構成 (左手ボール / 右手エンコーダー + ドングル)
# ------------------------------------------------------------------------------
build_leftball_l() {
    echo "=== Building Left-ball Left Peripheral (mtk64_leftball_L 1000Hz ESB ID:1) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/leftball_l -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_leftball_L rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n \
      -DCONFIG_ZMK_BLE=n \
      -DCONFIG_ZMK_SPLIT_BLE=n \
      -DCONFIG_ZMK_SPLIT_ESB=y \
      -DCONFIG_ZMK_SPLIT_ESB_PERIPHERAL_ID=1
    cp "${WORKSPACE}/build/leftball_l/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_L_leftball.uf2"
    echo "-> Left-ball Left firmware built: ${OUTPUT_DIR}/mtk64_L_leftball.uf2"
}

build_leftball_r() {
    echo "=== Building Left-ball Right Peripheral (mtk64_leftball_R 1000Hz ESB ID:2) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/leftball_r -b xiao_ble//zmk -s zmk/app -- \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_leftball_R rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n \
      -DCONFIG_ZMK_BLE=n \
      -DCONFIG_ZMK_SPLIT_BLE=n \
      -DCONFIG_ZMK_SPLIT_ESB=y \
      -DCONFIG_ZMK_SPLIT_ESB_PERIPHERAL_ID=2
    cp "${WORKSPACE}/build/leftball_r/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_R_leftball.uf2"
    echo "-> Left-ball Right firmware built: ${OUTPUT_DIR}/mtk64_R_leftball.uf2"
}

# ------------------------------------------------------------------------------
# 4. ユーティリティ
# ------------------------------------------------------------------------------
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
    right_direct|right_ble)
        build_right_direct
        ;;
    right_foot)
        build_right_foot
        ;;
    left_direct|left_ble)
        build_left_direct
        ;;
    foot_direct|foot_ble)
        build_foot_direct
        ;;
    right_dongle|right_esb)
        build_right_dongle
        ;;
    left_dongle|left_esb)
        build_left_dongle
        ;;
    foot_dongle|foot_esb)
        build_foot_dongle
        ;;
    right|R|r)
        build_right_direct
        build_right_foot
        build_right_dongle
        ;;
    left|L|l)
        build_left_direct
        build_left_dongle
        ;;
    dongle|DONGLE)
        build_dongle
        build_right_dongle
        build_left_dongle
        ;;
    dongle_nodisplay)
        build_dongle_nodisplay
        build_right_dongle
        build_left_dongle
        ;;
    leftball|left_ball)
        build_leftball_l
        build_leftball_r
        build_dongle
        ;;
    foot|FOOT)
        build_foot_direct
        build_foot_dongle
        ;;
    reset)
        build_reset
        ;;
    all|ALL)
        build_right_direct
        build_right_foot
        build_left_direct
        build_foot_direct
        build_dongle
        build_dongle_nodisplay
        build_right_dongle
        build_left_dongle
        build_foot_dongle
        build_leftball_l
        build_leftball_r
        build_reset
        ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Options: all, right, left, dongle, dongle_nodisplay, leftball, foot, reset, right_direct, right_foot, right_dongle"
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

    # 3. Right + Left + Dongle (no OLED)
    if [ -f "mtk64_DONGLE.uf2" ] && [ -f "mtk64_R_dongle.uf2" ] && [ -f "mtk64_L_dongle.uf2" ]; then
        zip -q "mtk64ebt_Right_Left_Dongle.zip" mtk64_DONGLE.uf2 mtk64_R_dongle.uf2 mtk64_L_dongle.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle.zip"
    fi

    # 4. Right + Left + Dongle (with OLED display)
    if [ -f "mtk64_DONGLE_display.uf2" ] && [ -f "mtk64_R_dongle.uf2" ] && [ -f "mtk64_L_dongle.uf2" ]; then
        zip -q "mtk64ebt_Right_Left_Dongle_display.zip" mtk64_DONGLE_display.uf2 mtk64_R_dongle.uf2 mtk64_L_dongle.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle_display.zip"
    fi

    # 5. Right + Left + Dongle (with OLED) + Foot
    if [ -f "mtk64_DONGLE_display.uf2" ] && [ -f "mtk64_R_dongle.uf2" ] && [ -f "mtk64_L_dongle.uf2" ] && [ -f "mtk64_FOOT_dongle.uf2" ]; then
        mkdir -p pkg_dongle_foot
        cp mtk64_DONGLE_display.uf2 pkg_dongle_foot/
        cp mtk64_R_dongle.uf2 pkg_dongle_foot/
        cp mtk64_L_dongle.uf2 pkg_dongle_foot/
        cp mtk64_FOOT_dongle.uf2 pkg_dongle_foot/mtk64_FOOT.uf2
        cp settings_reset.uf2 pkg_dongle_foot/ 2>/dev/null || true
        (cd pkg_dongle_foot && zip -q "../mtk64ebt_Right_Left_Dongle_disp_foot.zip" *.uf2)
        rm -rf pkg_dongle_foot
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle_disp_foot.zip"
    fi

    # 6. Left-ball + Right-encoder + Dongle (with OLED)
    if [ -f "mtk64_DONGLE_display.uf2" ] && [ -f "mtk64_L_leftball.uf2" ] && [ -f "mtk64_R_leftball.uf2" ]; then
        zip -q "mtk64ebt_Right_Left_Dongle_disp_leftball.zip" mtk64_DONGLE_display.uf2 mtk64_L_leftball.uf2 mtk64_R_leftball.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle_disp_leftball.zip"
    fi
}

package_zips

echo "=== Build Complete ==="
