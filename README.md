# README

mtk64ebt Rev4用ファームウェアです。

> [!NOTE]
> mtk64ebt Rev3用ファームウェアについては、各 `_rev3` ブランチ（例: [right_left_rev3 ブランチの README](https://github.com/mentako-ya/zmk-config-mtk64/tree/right_left_rev3#readme)）を参照してください。


### キーマップの変更

キーマップはブラウザで変更可能です。右手側をUSB接続して https://zmk.studio/ にアクセスしてください。

https://zmk.studio/download　からアプリ版をダウンロードすれば、無線接続のままキーマップ変更が可能です。

必要に応じて、[studio_unlockキー](https://zmk.dev/docs/features/studio#keymap-changes)（レイヤー１右手右上のキー）でUNLOCKして書き換えてください。

### キーボードの接続

キーボードの電源を入れ、右、左、フットスイッチのリセットボタンを１回押してキーボード間をペアリングしてください。

PCからBlutoothでmtk64erpを選択して接続してください。

コードの入力を求められた場合、指定されたコードをキーボードから入力してEnterキーを押下してください。

キーボードの状態はUSB端子右にあるLEDで確認します。
- バッテリーレベルに応じて起動時に🟢/🟡/🔴を点滅
- バッテリーレベルが臨界レベル以下の場合、バッテリーレベルの変化ごとに🔴を点滅
- BTプロファイルの切り替えごとに、接続中は🔵、オープンは🟡、切断中は🔴を点滅（右手側）
- 左手とフットスイッチは、接続中は🔵、切断中は🔴を点滅

https://github.com/caksoylar/zmk-rgbled-widget

### レイヤー別トラックボールの動作
- レイヤ−１ トラックボール精密モード    右手キーボードはマウスボタン操作用マッピング　トラックボールのカーソル動作が精密モード
- レイヤ−２ トラックボールモード       右手キーボードはマウスボタン操作用マッピング
- レイヤ−３ スクロールモード　         トラックボールでスクロール
- レイヤ−６ オートマウスレーイヤー　　　右手キーボードはマウスボタン操作用マッピング　オートマウスレイヤ動作時の遷移先　         

## 提供ファームウェア構成一覧（mainブランチで一括ビルド）

本リポジトリ（`main` ブランチ）では、以下の 6 種類のハードウェア構成に対応したファームウェアが一括ビルドされ、GitHub Actions リリースおよびローカルビルドにて ZIP パッケージとして自動生成されます。

| No | 構成名 | パッケージ名 (ZIP) | 含まれるファームウェア (.uf2) |
| :--- | :--- | :--- | :--- |
| 1 | **左右構成（直接PC接続）** | `mtk64ebt_Right_Left.zip` | `mtk64_R.uf2`, `mtk64_L.uf2`, `settings_reset.uf2` |
| 2 | **左右＋フットスイッチ** | `mtk64ebt_Right_Left_Foot.zip` | `mtk64_R.uf2`, `mtk64_L.uf2`, `mtk64_FOOT.uf2`, `settings_reset.uf2` |
| 3 | **左右＋ドングル（画面なし）** | `mtk64ebt_Right_Left_Dongle.zip` | `mtk64_DONGLE.uf2`, `mtk64_R_dongle.uf2`, `mtk64_L.uf2`, `settings_reset.uf2` |
| 4 | **左右＋ドングルOLED** | `mtk64ebt_Right_Left_Dongle_display.zip` | `mtk64_DONGLE_display.uf2`, `mtk64_R_dongle.uf2`, `mtk64_L.uf2`, `settings_reset.uf2` |
| 5 | **左右＋ドングルOLED＋フット** | `mtk64ebt_Right_Left_Dongle_disp_foot.zip` | `mtk64_DONGLE_display.uf2`, `mtk64_R_dongle.uf2`, `mtk64_L.uf2`, `mtk64_FOOT.uf2`, `settings_reset.uf2` |
| 6 | **左ボール右エンコーダー＋ドングルOLED** | `mtk64ebt_Right_Left_Dongle_disp_leftball.zip` | `mtk64_DONGLE_display.uf2`, `mtk64_L_leftball.uf2`, `mtk64_R_leftball.uf2`, `settings_reset.uf2` |

> 全構成をまとめた `mtk64ebt_All.zip` も同時に生成されます。

---

## フォークとカスタマイズ
リポジトリをフォークして、キーマップや各種設定のカスタマイズにご使用いただけます。

1. **リポジトリのフォーク**:
   * GitHub 画面右上の「Fork」ボタンをクリックして、ご自身のアカウントにフォークします。
   * ※ 初回のみ、フォーク先リポジトリの **「Actions」タブ** を開き、**「I understand my workflows, go ahead and enable them」** をクリックして GitHub Actions を有効化してください。

2. **ローカルへクローン**:
   ```sh
   git clone https://github.com/<your_username>/zmk-config-mtk64.git
   cd zmk-config-mtk64
   ```

3. **本家（upstream）リポジトリの登録**:
   ```sh
   git remote add upstream https://github.com/mentako-ya/zmk-config-mtk64.git
   ```

4. **最新の更新を取り込む場合**:
   ```sh
   git fetch upstream
   git merge upstream/main
   ```

5. **キーマップの変更とプッシュ**:
   * `config/mtk64.keymap` などを編集後、コミットしてプッシュします。
   ```sh
   git add .
   git commit -m "feat: customize keymap"
   git push origin main
   ```

6. GitHubでプルリクエストを作成し、変更を共有していただけるとよろこびます。

---

## ファームウェアの自動ビルドと書き込み手順

### 1. 自動ビルドとダウンロード

変更をフォーク先リポジトリの `main` ブランチにプッシュすると、GitHub Actions が自動的に全 6 構成のファームウェアを一括ビルドします。

ビルド完了後、ファームウェア（ZIP）は以下のいずれかからダウンロードできます：

* **方法 A（推奨：Releases からダウンロード）**:
  * フォーク先リポジトリの **「Releases」ページ**（右サイドバーの Releases または `latest-main` タグ）を開きます。
  * Assets の一覧から、ご自身のハードウェア構成に合った ZIP ファイル（例: `mtk64ebt_Right_Left_Dongle_display.zip`）をクリックしてダウンロードします。
* **方法 B（Actions 実行履歴からダウンロード）**:
  * **「Actions」タブ** $\to$ 最新のワークフロー実行結果を開きます。
  * ページ最下部の **「Artifacts」** 一覧からも各構成のファイルをダウンロードできます。

### 2. ZIP 内に含まれるファームウェア一覧

ZIP を解凍すると、構成に応じた `.uf2` ファイルが含まれています：

```text
mtk64_R.uf2 / mtk64_R_dongle.uf2       右手用ファームウェア
mtk64_L.uf2 / mtk64_L_leftball.uf2     左手用ファームウェア
mtk64_DONGLE_display.uf2 / DONGLE.uf2   ドングル親機用ファームウェア
mtk64_FOOT.uf2                         フットスイッチ用ファームウェア
settings_reset.uf2                     設定リセット用ファームウェア
```

### 3. デバイスへの書き込み（フラッシュ）手順

各モジュール（右手、左手、ドングル、フットスイッチ）へ対応するファームウェアを書き込みます：

1. **USB 接続**: 書き込むデバイスを USB ケーブルで PC に接続します。
2. **ブートローダー起動**: Xiao BLE 基板上のリセットスイッチを **素早く 2 回（ダブルクリック）** 押します。PC にリムーバブルディスク **`XIAO-SENSE`** がマウントされます。
3. **設定リセット（初回または動作不安定時）**:
   * `settings_reset.uf2` を `XIAO-SENSE` ドライブへドラッグ＆ドロップします。書き込み後、自動的に再起動します。
4. **ファームウェア書き込み**:
   * 再度リセットスイッチをダブルクリックして `XIAO-SENSE` を開き、対応するファームウェア（例: 右手なら `mtk64_R.uf2`）をドラッグ＆ドロップして書き込みます。
