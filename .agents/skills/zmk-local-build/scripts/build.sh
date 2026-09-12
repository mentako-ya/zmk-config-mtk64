#!/bin/bash
set -e

# ==============================================================================
# mtk64ebt ドングル接続 (1000Hz ESB) ローカルビルドスクリプト (right_left_dongle_rev4)
# ==============================================================================
# PC ↔ ドングル(USB Central) ↔ 左右手/フット(1000Hz ESB 超低遅延通信)
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
# 1. ドングル親機 (Centrals)
# ------------------------------------------------------------------------------
build_dongle() {
    echo "=== Building Dongle with Display (mtk64_DONGLE + OLED Central) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/dongle_display -b xiao_ble//zmk -s zmk/app -- \
      -DPython3_EXECUTABLE="/Users/tools/.pyenv/versions/3.13.5/bin/python3.13" \
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
      -DPython3_EXECUTABLE="/Users/tools/.pyenv/versions/3.13.5/bin/python3.13" \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="mtk64_DONGLE rgbled_adapter" \
      -DZMK_CONFIG="${REPO_ROOT}/config" \
      -DSNIPPET="studio-rpc-usb-uart" \
      -DCONFIG_ZMK_STUDIO=y \
      -DCONFIG_ZMK_DISPLAY=n
    cp "${WORKSPACE}/build/dongle/zephyr/zmk.uf2" "${OUTPUT_DIR}/mtk64_DONGLE.uf2"
    echo "-> Dongle (no display) firmware built: ${OUTPUT_DIR}/mtk64_DONGLE.uf2"
}

# ------------------------------------------------------------------------------
# 2. 標準構成ペリフェラル (ESB Peripherals: 右手トラックボール / 左手キー)
# ------------------------------------------------------------------------------
build_right_dongle() {
    echo "=== Building Right ESB Peripheral (mtk64_R 1000Hz ESB ID:2) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/right_dongle -b xiao_ble//zmk -s zmk/app -- \
      -DPython3_EXECUTABLE="/Users/tools/.pyenv/versions/3.13.5/bin/python3.13" \
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
    echo "=== Building Left ESB Peripheral (mtk64_L 1000Hz ESB ID:1) ==="
    cd "$WORKSPACE"
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_SDK_INSTALL_DIR="$SDK_PATH" \
    west build -p -d build/left_dongle -b xiao_ble//zmk -s zmk/app -- \
      -DPython3_EXECUTABLE="/Users/tools/.pyenv/versions/3.13.5/bin/python3.13" \
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
      -DPython3_EXECUTABLE="/Users/tools/.pyenv/versions/3.13.5/bin/python3.13" \
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
      -DPython3_EXECUTABLE="/Users/tools/.pyenv/versions/3.13.5/bin/python3.13" \
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
      -DPython3_EXECUTABLE="/Users/tools/.pyenv/versions/3.13.5/bin/python3.13" \
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
      -DPython3_EXECUTABLE="/Users/tools/.pyenv/versions/3.13.5/bin/python3.13" \
      -DZephyr-sdk_DIR="$SDK_DIR" \
      -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
      -DSHIELD="settings_reset" \
      -DZMK_CONFIG="${REPO_ROOT}/config"
    cp "${WORKSPACE}/build/reset/zephyr/zmk.uf2" "${OUTPUT_DIR}/settings_reset.uf2"
    echo "-> Settings reset firmware built: ${OUTPUT_DIR}/settings_reset.uf2"
}

case "$TARGET" in
    dongle|DONGLE)
        build_dongle
        build_dongle_nodisplay
        build_right_dongle
        build_left_dongle
        ;;
    disp_foot|dongle_disp_foot)
        build_dongle
        build_right_dongle
        build_left_dongle
        build_foot_dongle
        build_reset
        ;;
    dongle_foot|foot_dongle|nodisp_foot)
        build_dongle_nodisplay
        build_right_dongle
        build_left_dongle
        build_foot_dongle
        build_reset
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
        build_foot_dongle
        ;;
    reset)
        build_reset
        ;;
    all|ALL)
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
        echo "Options: all, dongle, dongle_nodisplay, disp_foot, dongle_foot, leftball, foot, reset"
        exit 1
        ;;
esac

package_zips() {
    echo "=== Packaging Firmware ZIPs (5 Dongle Configurations) ==="
    cd "$OUTPUT_DIR"

    # 1. Right + Left + Dongle (with OLED display) + Foot
    if [ -f "mtk64_DONGLE_display.uf2" ] && [ -f "mtk64_R_dongle.uf2" ] && [ -f "mtk64_L_dongle.uf2" ] && [ -f "mtk64_FOOT_dongle.uf2" ]; then
        mkdir -p pkg_dongle_foot
        cp mtk64_DONGLE_display.uf2 pkg_dongle_foot/
        cp mtk64_R_dongle.uf2 pkg_dongle_foot/
        cp mtk64_L_dongle.uf2 pkg_dongle_foot/
        cp mtk64_FOOT_dongle.uf2 pkg_dongle_foot/mtk64_FOOT.uf2
        cp settings_reset.uf2 pkg_dongle_foot/ 2>/dev/null || true
        rm -f "mtk64ebt_Right_Left_Dongle_disp_foot.zip"
        (cd pkg_dongle_foot && zip -q "../mtk64ebt_Right_Left_Dongle_disp_foot.zip" *.uf2)
        rm -rf pkg_dongle_foot
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle_disp_foot.zip"
    fi

    # 2. Right + Left + Dongle (no OLED) + Foot
    if [ -f "mtk64_DONGLE.uf2" ] && [ -f "mtk64_R_dongle.uf2" ] && [ -f "mtk64_L_dongle.uf2" ] && [ -f "mtk64_FOOT_dongle.uf2" ]; then
        mkdir -p pkg_dongle_nodisp_foot
        cp mtk64_DONGLE.uf2 pkg_dongle_nodisp_foot/
        cp mtk64_R_dongle.uf2 pkg_dongle_nodisp_foot/
        cp mtk64_L_dongle.uf2 pkg_dongle_nodisp_foot/
        cp mtk64_FOOT_dongle.uf2 pkg_dongle_nodisp_foot/mtk64_FOOT.uf2
        cp settings_reset.uf2 pkg_dongle_nodisp_foot/ 2>/dev/null || true
        rm -f "mtk64ebt_Right_Left_Dongle_foot.zip"
        (cd pkg_dongle_nodisp_foot && zip -q "../mtk64ebt_Right_Left_Dongle_foot.zip" *.uf2)
        rm -rf pkg_dongle_nodisp_foot
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle_foot.zip"
    fi

    # 3. Right + Left + Dongle (with OLED display)
    if [ -f "mtk64_DONGLE_display.uf2" ] && [ -f "mtk64_R_dongle.uf2" ] && [ -f "mtk64_L_dongle.uf2" ]; then
        rm -f "mtk64ebt_Right_Left_Dongle_display.zip"
        zip -q "mtk64ebt_Right_Left_Dongle_display.zip" mtk64_DONGLE_display.uf2 mtk64_R_dongle.uf2 mtk64_L_dongle.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle_display.zip"
    fi

    # 4. Right + Left + Dongle (no OLED)
    if [ -f "mtk64_DONGLE.uf2" ] && [ -f "mtk64_R_dongle.uf2" ] && [ -f "mtk64_L_dongle.uf2" ]; then
        rm -f "mtk64ebt_Right_Left_Dongle.zip"
        zip -q "mtk64ebt_Right_Left_Dongle.zip" mtk64_DONGLE.uf2 mtk64_R_dongle.uf2 mtk64_L_dongle.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle.zip"
    fi

    # 5. Left-ball + Right-encoder + Dongle (with OLED)
    if [ -f "mtk64_DONGLE_display.uf2" ] && [ -f "mtk64_L_leftball.uf2" ] && [ -f "mtk64_R_leftball.uf2" ]; then
        rm -f "mtk64ebt_Right_Left_Dongle_disp_leftball.zip"
        zip -q "mtk64ebt_Right_Left_Dongle_disp_leftball.zip" mtk64_DONGLE_display.uf2 mtk64_L_leftball.uf2 mtk64_R_leftball.uf2 settings_reset.uf2 2>/dev/null || true
        echo "-> Packaged: ${OUTPUT_DIR}/mtk64ebt_Right_Left_Dongle_disp_leftball.zip"
    fi
}

package_zips

echo "=== Build Complete ==="
