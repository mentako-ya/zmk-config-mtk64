# Project Rules for zmk-config-mtk64

## 厳格ルール
- `/Users/tools/git/badjeff-pmw3610-driver` (PMW3610ドライバ) の参照、比較、およびコードの流用・混同は**一切禁止**する。
- `/Users/tools/git/zmk-driver-paw3222` (外部 PAW3222 ドライバモジュール) の参照、比較は**一切禁止**する。
- PAW3222 の実装・解析を行う際は、必ず PAW3222 固有の正統参照元（`mochibella-zmk-config`、`zmk-badjeff` / Zephyr 純正 `input_paw32xx.c`）のみを使用すること。
