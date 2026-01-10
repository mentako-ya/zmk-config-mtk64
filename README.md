# README

mtk64ebt用zmkファームウェアです。

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

## フォークとカスタマイズ
リポジトリをフォークして、キーマップや各種機能のカスタマイズにご使用ください。

1. GitHubでこのリポジトリをフォークします。

2. フォークしたリポジトリをクローンします。

    ```sh
    git clone https://github.com/<your_username>/zmk-config-mtk64.git
    cd zmk-config-mtk64
    ```

3. オリジナルのリポジトリ（upstream）をリモートとして追加します。

    ```sh
    git remote add upstream https://github.com/yourusername/zmk-config-mtk64.git
    ```

4. 必要に応じてリモートから最新の変更を取得し、マージします。

    ```sh
    git fetch upstream
    git merge upstream/main
    ```

5. カスタマイズを行い、変更をコミットします。

    ```sh
    git add .
    git commit -m "カスタマイズの説明"
    git push origin main
    ```

6. GitHubでプルリクエストを作成し、変更を共有していただけるとよろこびます。

## ファームウェアのビルドと書き込み

1. フォークしたリポジトリに変更をプッシュすると、GitHub Actionsが自動的にビルドを開始します。

    GitHubのActionsタブでビルドの進行状況を確認できます。
    
    build / Merge Output Artifacts　のログを開き、'Artifact download URL'　のリンクからzipファイルをダウンロードします。
    ```
    Artifact download URL: https://github.com/<your_username>/zmk-config-mtk64/actions/runs/xxxxxxx/artifacts/xxxxxx
    ```

3. ビルドしたファームウェアをダウンロードして解凍します。

    ```
    mtk64_R rgbled_adapter-xiao_ble-zmk.uf2       右手用ファームウェア
    mtk64_L rgbled_adapter-xiao_ble-zmk.uf2       左手用ファームウェア
    mtk64_FOOT rgbled_adapter-xiao_ble-zmk.uf2    フットスイッチ用ファームウェア
    settings_reset-xiao_ble-zmk.uf2               リセット用ファイル
    ```

4. USBケーブルでキーボードを接続して、リセットスイッチをダブルクリックすると、リムーバブルディスク"XIAO-SENSE"として認識されます。

    まず　settings_reset-xiao_ble-zmk.uf2　をリムーバブルディスクに書き込み、再度リセットスイッチをダブルクリックして、新しいファームウェアを書き込んでください。
