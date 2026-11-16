# CaptionBridge 0.2.0 发布说明

产品名称：CaptionBridge（中文：听桥；日文介绍名：ことばブリッジ）。这是项目使用的名称，未进行商标或名称独占性核验。

## 本地构建与安装包

```sh
zsh scripts/build.sh
zsh scripts/package.sh
```

产物为 `dist/CaptionBridge-0.2.0-macOS-arm64.dmg`、三语 HTML 指南和 SHA-256 校验文件。DMG 内有 App、Applications 快捷方式及指南；使用者无需开发工具。当前只编译 arm64，最低系统 macOS 27.0。

App 保持原来的 bundle ID `local.bilingualcaptions.app`，以便延续设置。未来若更换为开发者自有域名的 bundle ID，应视为新的 App 身份并重新测试授权。版本 0.2.0 的文件名改为 CaptionBridge.app。

## 当前签名与公证状态

当前环境没有有效代码签名证书，因此本次包是 ad hoc 本地签名，启用 Hardened Runtime，未进行 Apple 公证。它可以用于本机及受控测试，但不能描述为在任意 Mac 上无提示打开的正式发行版。不要通过清除 quarantine、关闭 Gatekeeper 或篡改 TCC 来使安装测试通过。

正式对外分发需要开发者提供 Developer ID Application 证书与已配置的 Apple 公证凭据。构建脚本接受已有证书名称和 Keychain profile；不在代码或仓库中保存账号密码：

```sh
export CAPTIONBRIDGE_SIGN_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)'
export CAPTIONBRIDGE_NOTARY_PROFILE='YOUR_EXISTING_KEYCHAIN_PROFILE'
zsh scripts/package.sh
```

脚本会签署 App、提交 DMG 公证、等待、staple 并验证，然后生成校验文件。用户未授权上传前，不执行公证提交。对外发布前还应在另一台干净的 Apple Silicon Mac 上验证首次模型下载、安装、权限申请和音频采集。

官方要求：[Developer ID 与公证](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)。

## 已知边界

- 三语对应的是界面、介绍和指引，字幕仍为英语识别与英译简体中文。
- 所有电脑输出音频都可能被识别；目前不能按 App 选择，也不混入麦克风。
- 测试通过不代表长会议、多屏、休眠恢复等场景都已验证。
- 重新进行 ad hoc 签名可能触发重新授权。稳定的 Developer ID 身份与固定安装路径仍需发布前验证。
