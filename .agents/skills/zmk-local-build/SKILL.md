---
name: zmk-local-build
description: >-
  ZMK firmware local build workflow and helper scripts for mtk64.
  Use when the user requests local builds, compiling firmware locally,
  troubleshooting Zephyr SDK toolchain errors, or flashing .uf2 binaries for mtk64_L/mtk64_R.
---

# ZMK Local Build Skill for mtk64

本スキルは、`zmk-config-mtk64` のファームウェアをローカル環境でビルドし、XIAO BLE 向け `.uf2` ファイルを生成・書き込むためのワークフローおよび仕様です。

---

## 1. クイック実行（ヘルパースクリプト）

スキル内に同梱されたビルドスクリプトを実行することで、左右両方または個別のファームウェアを一括ビルドできます。

### 全構成一括ビルド
```bash
/Users/tools/git/zmk-config-mtk64/.agents/skills/zmk-local-build/scripts/build.sh all
```

### 個別・構成別ビルド
* **左手のみ**: `build.sh left`
* **右手のみ**: `build.sh right`
* **ドングル（OLED画面あり）**: `build.sh dongle`
* **ドングル（画面なし）**: `build.sh dongle_nodisplay`
* **左ボール右エンコーダー構成**: `build.sh leftball`
* **フットスイッチ**: `build.sh foot`
* **設定リセット用**: `build.sh reset`

ビルドが完了すると、自動的に作業用ディレクトリ（`/Users/tools/git/zmk-config-mtk64/firmware/`）に各 `.uf2` および 6 構成の ZIP パッケージが出力されます：
* `mtk64ebt_Right_Left.zip`（左右直接接続）
* `mtk64ebt_Right_Left_Foot.zip`（左右＋フット）
* `mtk64ebt_Right_Left_Dongle.zip`（ドングル画面なし）
* `mtk64ebt_Right_Left_Dongle_display.zip`（ドングルOLED）
* `mtk64ebt_Right_Left_Dongle_disp_foot.zip`（ドングルOLED＋フット）
* `mtk64ebt_Right_Left_Dongle_disp_leftball.zip`（左ボール右エンコーダー＋ドングルOLED）

---

## 2. 手動 `west build` コマンド仕様

手動で細かくパラメータを指定してビルドする場合のコマンド仕様です。  
実行ディレクトリ: `/Users/tools/git/zmk-build-workspace`

### ① 左手側 (`mtk64_L`)
```bash
ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
ZEPHYR_SDK_INSTALL_DIR=/Users/tools/zephyr-sdk-0.17.0 \
west build -d build/left -b xiao_ble//zmk -s zmk/app -- \
  -DZephyr-sdk_DIR="/Users/tools/zephyr-sdk-0.17.0/cmake" \
  -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
  -DSHIELD="mtk64_L rgbled_adapter" \
  -DZMK_CONFIG="/Users/tools/git/zmk-config-mtk64/config"
```

### ② 右手側 (`mtk64_R` / ZMK Studio 有効)
```bash
ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
ZEPHYR_SDK_INSTALL_DIR=/Users/tools/zephyr-sdk-0.17.0 \
west build -d build/right -b xiao_ble//zmk -s zmk/app -- \
  -DZephyr-sdk_DIR="/Users/tools/zephyr-sdk-0.17.0/cmake" \
  -DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++ \
  -DSHIELD="mtk64_R rgbled_adapter" \
  -DZMK_CONFIG="/Users/tools/git/zmk-config-mtk64/config" \
  -DCONFIG_ZMK_STUDIO=y \
  -DSNIPPET="studio-rpc-usb-uart"
```

---

## 3. 環境構成と重要ポイント

1. **Zephyr SDK 0.17.0**:
   * Zephyr 4.1 の推奨 SDK である `0.17.0`（ARM minimal ツールチェーン）を使用します。
2. **C++ コンパイラ**:
   * `-DCMAKE_CXX_COMPILER=/opt/homebrew/bin/arm-none-eabi-g++` を指定することで、C++ コンパイラ探索エラーを回避します。
3. **macOS Quarantine 属性**:
   * SDK ツールチェーン実行時に `Killed: 9` が発生する場合は、`xattr -dr com.apple.quarantine /Users/tools/zephyr-sdk-0.17.0` を実行します。

---

## 4. 書き込み（UF2）手順

1. **左手側**:
   * 左手側 XiaoBLE を USB 接続 $\to$ リセットスイッチを **ダブルクリック** $\to$ マウントされた `XIAO-SENSE` に `firmware/mtk64_L.uf2` をコピー。
2. **右手側**:
   * 右手側 XiaoBLE を USB 接続 $\to$ リセットスイッチを **ダブルクリック** $\to$ マウントされた `XIAO-SENSE` に `firmware/mtk64_R.uf2` をコピー。
