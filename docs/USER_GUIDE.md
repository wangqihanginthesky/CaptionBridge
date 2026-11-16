# CaptionBridge 使用指南 / User Guide / 使い方ガイド

[简体中文](#简体中文) · [English](#english) · [日本語](#日本語)

## 简体中文

### 安装与首次使用

1. 要求 Apple Silicon 和 macOS 27 或更新版本，不支持 Intel Mac。
2. 从仓库 [Releases](https://github.com/wangqihanginthesky/CaptionBridge/releases) 下载 DMG。
3. 将 CaptionBridge.app 拖到 Applications（应用程序）；弹出磁盘映像后，从应用程序文件夹启动。
4. 选择界面语言，点击「准备语言模型」，按 Apple 弹窗下载英语和简体中文语言，再等待英语语音识别模型准备好。首次需要联网。
5. 点击「运行示例」验证本地识别与翻译，不需要录制权限。
6. 点击「开始字幕」，到下面的设置中允许录制，按要求重启 App，再开始播放英文会议或视频。

### 开启录制权限

**系统设置 → 隐私与安全性 → 屏幕与系统音频录制 → CaptionBridge**

允许 CaptionBridge；如果列表中没有它，先点击 App 的「开始字幕」，或用「＋」添加 Applications 中的 CaptionBridge.app。按系统提示用 Touch ID 或本机密码认证。如果出现「退出并重新打开」，请按提示操作。

系统把权限归类为屏幕与音频录制；App 仅消费音频缓冲，不保存屏幕画面。此版本不需要辅助功能权限，也不需要麦克风权限。重新进行本地临时签名后，可能需要重新授权。

### 使用与排查

- 菜单栏的字幕图标可开始、停止、显示窗口或退出。
- 拖动悬浮窗调整位置，拖动边缘调整大小；控制窗口可调字号与背景透明度。
- 没有字幕时，确认有英语声音输出、会议没有静音、权限开启，并先运行示例检查模型。
- 默认 Low Latency 优先速度。High Fidelity 在可用时优先质量，必要时由 Apple 框架回退；切换在下次启动字幕时生效。
- 目前字幕为英语 → 简体中文。三语指的是界面与指南，不代表三种字幕翻译方向。

### 隐私与测试版状态

识别和翻译在本机完成。App 不采集麦克风、不上传会议内容、不保存音频或字幕文件。模型下载与更新需要网络，准备好后识别与翻译可离线运行。电脑中其他 App 的英语声音也可能被识别，暂不支持按 App 选择。

此包尚无 Developer ID 签名和 Apple 公证，经互联网下载后可能被系统阻止打开。请仅使用可信来源并阅读 [Apple 官方说明](https://support.apple.com/102445)，不要关闭系统安全检查。完整中英日 HTML 指南包含在 DMG 和 Release 下载文件中。

## English

### Installation and first use

1. Requires Apple Silicon and macOS 27 or later; Intel Macs are not supported.
2. Download the DMG from [Releases](https://github.com/wangqihanginthesky/CaptionBridge/releases).
3. Drag CaptionBridge.app to Applications. Eject the disk image and launch the app from Applications.
4. Select an interface language. Click **Prepare language models** and download English and Simplified Chinese in Apple's sheet, then wait for the English speech model. Initial setup needs internet.
5. Click **Try a sample** to check local recognition and translation without recording permissions.
6. Click **Start captions**, allow recording as below, restart if requested, and play an English meeting or video.

### Recording permissions

**System Settings → Privacy & Security → Screen & System Audio Recording → CaptionBridge**

Enable CaptionBridge. If missing, click **Start captions** first or use **+** to add CaptionBridge.app from Applications. Confirm with Touch ID or your Mac password. Follow **Quit & Reopen** if prompted.

macOS groups this access under screen and audio recording. The app consumes only audio buffers and does not save screen images. Accessibility and microphone permissions are not needed. A new ad hoc signature may require granting permission again.

### Controls and troubleshooting

- Use the menu bar caption icon to start, stop, show windows, or quit.
- Drag the floating window to move it and its edges to resize it. Set caption size and opacity in the controls.
- If no captions appear, check English audio output, meeting mute status, and recording permissions. Try the sample to check models first.
- Low Latency prioritizes speed. High Fidelity prefers quality when available, with fallback handled by Apple's framework. Changes apply next time captions start.
- Captions currently translate English → Simplified Chinese. Three languages refer to the interface and guides, not three translation directions.

### Privacy and preview status

Recognition and translation run locally. No microphone capture, meeting-content uploads, or saved meeting audio/caption files. Model downloads and updates need internet; recognition and translation work offline after setup. Other English audio from the computer may be captured; per-app selection is not yet available.

This preview has no Developer ID signature and is not notarized by Apple. Other Macs may block internet-downloaded copies. Use a trusted source and read [Apple's guidance](https://support.apple.com/en-us/102445); do not disable security checks. The full trilingual HTML guide is included in the DMG and Release assets.

## 日本語

### インストールと初回利用

1. AppleシリコンとmacOS 27以降が必要です。Intel Macには対応していません。
2. [Releases](https://github.com/wangqihanginthesky/CaptionBridge/releases)からDMGをダウンロードします。
3. CaptionBridge.appをアプリケーションへドラッグし、ディスクイメージを取り出してからアプリケーションフォルダから起動します。
4. 表示言語を選び、**言語モデルを準備**をクリックします。Appleの画面で英語と簡体字中国語をダウンロードし、英語音声認識モデルの準備を待ちます。初回はインターネット接続が必要です。
5. **サンプルを試す**でローカル認識・翻訳を確認できます。録音のアクセス権は不要です。
6. **字幕を開始**をクリックし、以下のアクセス権を許可します。必要に応じてアプリを開き直し、英語の会議や動画を再生してください。

### 録音のアクセス権

**システム設定 → プライバシーとセキュリティ → 画面収録とシステムオーディオ録音 → CaptionBridge**

CaptionBridgeを許可します。一覧にない場合は先に**字幕を開始**をクリックするか、**＋**でアプリケーションフォルダ内のCaptionBridge.appを追加します。Touch IDまたはMacのパスワードで認証し、**終了して開き直す**と表示された場合はその指示に従ってください。

macOSでは画面収録と音声録音のアクセス権に分類されます。アプリは音声バッファのみを処理し、画面画像を保存しません。アクセシビリティとマイクのアクセス権は不要です。アドホック署名の変更により、再度の許可が必要になる場合があります。

### 操作とトラブルシューティング

- メニューバーの字幕アイコンから開始・停止・ウインドウ表示・終了を操作できます。
- 字幕ウインドウはドラッグで移動、端をドラッグしてサイズ変更できます。操作ウインドウで文字サイズと背景の不透明度を調整できます。
- 字幕が出ない場合は英語音声の出力、ミュート状態、録音のアクセス権を確認し、サンプルでモデルを検証してください。
- Low Latencyは速度、High Fidelityは利用可能な場合に品質を優先します。フォールバックはAppleのフレームワークが処理し、変更は次回の字幕開始時に反映されます。
- 現在の字幕方向は英語 → 簡体字中国語です。3言語対応とは表示とガイドを指し、3方向の翻訳を意味しません。

### プライバシーとプレビュー版

音声認識と翻訳はMac内で処理します。マイクは使用せず、会議内容のアップロード、音声・字幕ファイルの保存は行いません。モデルの取得と更新にはインターネット接続が必要ですが、準備後の認識と翻訳はオフラインで利用できます。他のアプリの英語音声も対象になり、アプリ別の選択は未対応です。

このプレビュー版はDeveloper ID署名とAppleの公証が未完了のため、インターネット経由のコピーは別のMacでブロックされる場合があります。信頼できる配布元を利用し、[Appleの案内](https://support.apple.com/ja-jp/102445)を確認してください。セキュリティチェックを無効にしないでください。DMGとReleaseには3言語対応のHTMLガイドも付属します。

## 系统名称对照 / System labels / 設定名

| 中文 | English | 日本語 |
|---|---|---|
| 系统设置 | System Settings | システム設定 |
| 隐私与安全性 | Privacy & Security | プライバシーとセキュリティ |
| 屏幕与系统音频录制 | Screen & System Audio Recording | 画面収録とシステムオーディオ録音 |
| 允许 | Allow | 許可 |
| 退出并重新打开 | Quit & Reopen | 終了して開き直す |
