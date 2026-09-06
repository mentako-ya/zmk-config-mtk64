# README

mtk64ebt Rev3用zmkファームウェアです。

> [!NOTE]
> mtk64ebt Rev4用ファームウェアについては、[main ブランチ](https://github.com/mentako-ya/zmk-config-mtk64/tree/main#readme) を参照してください。

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

## 各種Rev3ファームウェアおよびブランチについて
キーボードのハードウェア構成に応じたファームウェア（ZIP）およびソースコードブランチを使用してください。

### 1. 左右構成用（直接PC接続）
* **ファームウェア**: [mtk64ebt_Right_Left.zip](https://github.com/mentako-ya/mtk64ebt/raw/rev3/firmware/rev3/mtk64ebt_Right_Left.zip)
* **ソースコード**: [right_left_rev3 ブランチ](https://github.com/mentako-ya/zmk-config-mtk64/tree/right_left_rev3)
* **説明**: ドングルを使用せず、右手側をセントラル（親機）としてPCとBluetooth直接接続して使用する標準構成です。

### 2. 左右＋フットスイッチ無線化モジュール用
* **ファームウェア**: [mtk64ebt_Right_Left_Foot.zip](https://github.com/mentako-ya/mtk64ebt/raw/rev3/firmware/rev3/mtk64ebt_Right_Left_Foot.zip)
* **ソースコード**: [right_left_foot_rev3 ブランチ](https://github.com/mentako-ya/zmk-config-mtk64/tree/right_left_foot_rev3)
* **説明**: 左右キーボードに加え、無線フットスイッチモジュールを組み合わせて使用する構成です。

### 3. 左右＋ドングルモジュール用（画面なし）
* **ファームウェア**: [mtk64ebt_Right_Left_Dongle.zip](https://github.com/mentako-ya/mtk64ebt/raw/rev3/firmware/rev3/mtk64ebt_Right_Left_Dongle.zip)
* **ソースコード**: [right_left_dongle_rev3 ブランチ](https://github.com/mentako-ya/zmk-config-mtk64/tree/right_left_dongle_rev3)
* **説明**: [Seeed Studio XIAO BLE](https://jp.seeedstudio.com/Seeed-XIAO-BLE-nRF52840-p-5201.html) をドングル親機として使用する構成です。解凍したファイルのドングル用ファームウェアをドングルに書き込んでください。

### 4. 左右＋ドングルモジュールOLED用
* **ファームウェア**: [mtk64ebt_Right_Left_Dongle_display.zip](https://github.com/mentako-ya/mtk64ebt/raw/rev3/firmware/rev3/mtk64ebt_Right_Left_Dongle_display.zip)
* **ソースコード**: [right_left_dongle-display_rev3 ブランチ](https://github.com/mentako-ya/zmk-config-mtk64/tree/right_left_dongle-display_rev3)
* **説明**: OLEDディスプレイ付きドングル親機を使用する構成です。解凍したファイルのドングル用ファームウェアをドングルに書き込んでください。

### 5. 左右＋ドングルモジュールOLED＋フットスイッチ用
* **ファームウェア**: [mtk64ebt_Right_Left_Dongle_disp_foot.zip](https://github.com/mentako-ya/mtk64ebt/raw/rev3/firmware/rev3/mtk64ebt_Right_Left_Dongle_disp_foot.zip)
* **ソースコード**: [right_left_dongle-display_foot_rev3 ブランチ](https://github.com/mentako-ya/zmk-config-mtk64/tree/right_left_dongle-display_foot_rev3)
* **説明**: OLEDディスプレイ付きドングル親機に、左右キーボードおよび無線フットスイッチを接続して使用する構成です。

### 6. 左ボール右エンコーダー用
* **ファームウェア**: [mtk64ebt_Right_Left_leftball.zip](https://github.com/mentako-ya/mtk64ebt/raw/rev3/firmware/rev3/mtk64ebt_Right_Left_leftball.zip)
* **ソースコード**: [right_left_left-ball_rev3 ブランチ](https://github.com/mentako-ya/zmk-config-mtk64/tree/right_left_left-ball_rev3)
* **説明**: 左手側にトラックボール、右手側にロータリーエンコーダーを配置する構成です。

### 7. 左ボール右エンコーダー＋ドングルモジュールOLED用
* **ファームウェア**: [mtk64ebt_Right_Left_Dongle_disp_leftball.zip](https://github.com/mentako-ya/mtk64ebt/raw/rev3/firmware/rev3/mtk64ebt_Right_Left_Dongle_disp_leftball.zip)
* **ソースコード**: [right_left_dongle-display_left-ball_rev3 ブランチ](https://github.com/mentako-ya/zmk-config-mtk64/tree/right_left_dongle-display_left-ball_rev3)
* **説明**: 左ボール右エンコーダー構成で、OLEDディスプレイ付きドングル親機を介してPCと接続する構成です。

### 8. 左右＋ドングルモジュール(RAYTAC-MDBT50Q-RX)用
* **ファームウェア**: [mtk64ebt_Right_Left_Dongle-mdbt50q_rx.zip](https://github.com/mentako-ya/mtk64ebt/raw/rev3/firmware/rev3/mtk64ebt_Right_Left_Dongle-mdbt50q_rx.zip)
* **ソースコード**: [right_left_dongle-mdbt50q_rx_rev3 ブランチ](https://github.com/mentako-ya/zmk-config-mtk64/tree/right_left_dongle-mdbt50q_rx_rev3)
* **説明**: [RAYTAC-MDBT50Q-RX](https://www.switch-science.com/products/5531) をドングルとして使用するファームウェアです。


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
    mtk64_DONGLE rgbled_adapter-xiao_ble-zmk.uf2  ドングル用ファームウェア※
    mtk64_FOOT rgbled_adapter-xiao_ble-zmk.uf2    フットスイッチ用ファームウェア※
    settings_reset-xiao_ble-zmk.uf2               リセット用ファイル
    ```

    ※ ビルドしたファームウェアのブランチによって構成が変わります。

4. USBケーブルでキーボード、ドングル、フットスイッチモジュールを接続して、リセットスイッチをダブルクリックすると、リムーバブルディスク"XIAO-SENSE"として認識されます。

    まず　settings_reset-xiao_ble-zmk.uf2　をリムーバブルディスクに書き込み、再度リセットスイッチをダブルクリックして、新しいファームウェアを書き込んでください。
