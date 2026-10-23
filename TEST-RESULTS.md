# LumaView 1.7.2 验证记录

<!-- full-translation:start -->
[简体中文](docs/i18n/zh-Hans/TEST-RESULTS.md) · [繁體中文](docs/i18n/zh-Hant/TEST-RESULTS.md) · [English](docs/i18n/en/TEST-RESULTS.md) · [日本語](docs/i18n/ja/TEST-RESULTS.md) · [한국어](docs/i18n/ko/TEST-RESULTS.md) · [Français](docs/i18n/fr/TEST-RESULTS.md) · [Deutsch](docs/i18n/de/TEST-RESULTS.md) · [Español](docs/i18n/es/TEST-RESULTS.md) · [Italiano](docs/i18n/it/TEST-RESULTS.md) · [Português (Brasil)](docs/i18n/pt-BR/TEST-RESULTS.md) · [Русский](docs/i18n/ru/TEST-RESULTS.md) · [العربية](docs/i18n/ar/TEST-RESULTS.md) · [हिन्दी](docs/i18n/hi/TEST-RESULTS.md) · [Türkçe](docs/i18n/tr/TEST-RESULTS.md) · [Nederlands](docs/i18n/nl/TEST-RESULTS.md) · [Polski](docs/i18n/pl/TEST-RESULTS.md)
<!-- full-translation:end -->


版本 1.7.2，build 14。2026-10-22，macOS 15.7.9 / Intel。应用与内置工具通过 arm64 + x86_64 通用架构与本地签名核验；本轮未在 Apple Silicon 硬件运行。

## 本次修复

栅格图片统一直接显示透明区域：PNG / GIF / PSD / PSB 等不再叠加灰白棋盘或画布矩形边框。显示阴影来自当前画面实际合成透明度，而不是整张图片画布；因此透明边距没有额外矩形阴影，镂空、独立软蒙版和半透明区域参与实际轮廓。

原实现仅根据 CGImage.alphaInfo 添加棋盘，遗漏带独立 Quartz mask 的 PSB；且每次缩放都强制安装矩形 shadowPath，边框本身也会形成矩形阴影。现在栅格图去掉这些矩形来源，图层阴影由合成 alpha 自动形成。绘图导出路径同样对图片本身投影，不预先填充矩形。GIF / APNG 换帧继续替换当前纹理，阴影随帧更新；无需每帧扫描透明像素或额外构造整幅 RGBA 图。

文档页面的白色纸面与视频矩形表面仍保留其现有显示方式；复制图片继续使用原图像素，不带查看背景、棋盘或显示阴影。没有更改 PSB 解码器、缩略图调度或上版的快速预览实现。

## 本轮验证

| 项目 | 通过 |
| --- | --- |
| 透明区域、轮廓阴影与换帧 | 133 / 133 |
| 画布几何、动画与鼠标 | 66 / 66 |
| 文档解析与完整页绘制 | 56 / 56 |
| 正式安装版文档、EPS / PS 缩放翻页与焦点 | 75 / 75 |
| 正式安装版右键菜单与复制 | 28 / 28 |
| 合计 | 358 / 358 |

透明测试为同一带镂空、不规则突出部分和较大透明边距的图形，分别使用 RGBA、独立 Quartz mask、真实编码并解码的 PNG、GIF、PSD、PSB。检查 CALayer 合成与 draw 导出像素，验证透明边缘无矩形底板/阴影、内外轮廓有阴影；还覆盖全透明图片、换帧、旋转缩放、快速切换及半透明查看背景。已人工查看导出 PNG。

上述六种输入的 CALayer 导出和 PNG draw 导出的 PNG SHA-256 完全一致：`578021195e2a41b30187ebc271542d599aecba7f0b9204fbfdf21eb680cac18c`。测试素材由代码生成，未把用户照片加入源码。

额外进行了有界软件绘制探针：32 MP 位图，逻辑画布包含 16,384 × 7,812 和 300,000 × 128，分别在适合窗口、100%、3200% 下比较新旧阴影。测试进程峰值 RSS 约 428 MiB，新旧绘制耗时相近；这是 CALayer.render(in:) 的软件快照开销，不是 GPU 帧率结论。没有因此加入图层栅格缓存。

正式安装版与 outputs/LumaView.app 完整文件清单和哈希一致，均通过 codesign --verify --deep --strict。安装前保留旧版 ZIP 备份；默认打开关联经前后读回核对。ZIP 交付包随后执行 CRC 和版本校验。历史报告保留在 Tests/Release-1.7.0.md 与 Tests/Release-1.7.1.md；旧版未重跑的检查不加入本轮数量。

主程序 SHA-256：`b022867c703cb1cdc94c31589d040356a5ec2be9bc5dd0c17395d323f8556d4e`。

## 日志来源

- `Transparency-test-results.txt` ← `work/transparency-1.7.2/transparency-test-results.txt`
- `Canvas-test-results.txt` ← `work/canvas-1.7.2-run.log`
- `Document-core-test-results.txt` ← `work/document-release-1.7.2/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-release-1.7.2/document-test-results.txt`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.2/context-menu-test-results.txt`
