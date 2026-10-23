> 历史验证记录中的个人样本文件名已匿名化；测试数据与结果保持原样。

<!-- doc-navigation:start -->
[文档目录](../INDEX.md) · **简体中文** · [繁體中文](../../zh-Hant/Tests/Release-1.7.0.md) · [English](../../en/Tests/Release-1.7.0.md) · [日本語](../../ja/Tests/Release-1.7.0.md) · [한국어](../../ko/Tests/Release-1.7.0.md) · [Français](../../fr/Tests/Release-1.7.0.md) · [Deutsch](../../de/Tests/Release-1.7.0.md) · [Español](../../es/Tests/Release-1.7.0.md) · [Italiano](../../it/Tests/Release-1.7.0.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.0.md) · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · [Türkçe](../../tr/Tests/Release-1.7.0.md) · [Nederlands](../../nl/Tests/Release-1.7.0.md) · [Polski](../../pl/Tests/Release-1.7.0.md)
<!-- doc-navigation:end -->

# LumaView 1.7.0 验证记录

日期：2026-10-22（Asia/Shanghai）。本轮运行环境：macOS 15.7.9、x86_64。应用目标为 macOS 13+，四个可执行文件均为 Intel / Apple Silicon 通用版。

## 本次改动与实测结果

- 应用内置 Ghostscript 10.08.0，直接打开 EPS、PostScript 和旧式 PostScript AI 时，在后台生成保留矢量路径、文字及原嵌入图像的 PDF，再交给现有画布。无需用户另装解释器或手动转换；缩放、拖动、旋转和多页导航沿用当前交互。内嵌 TIFF 回退仍用于无法完成矢量转换而文件提供预览的情况，不将位图回退标记为矢量。
- 实测原附件 `sample-vector.eps` 已使用完整 PostScript 内容。生成 PDF 扫描得到 **147,521 次路径/渐变相关操作、59 次文字操作、160 次 XObject 调用**。这里 XObject 数量按 PDF `Do` 操作统计，可能包含图像或 Form，不能等同为独立图片张数。测试确认保留真实矢量内容；原 EPS 与 `sample-vector.svg` 均经过测试前后 SHA-256 比较，原件未改变。
- PostScript 使用独立可取消进程、Ghostscript SAFER 和系统进程沙盒；输入复制到专用临时目录，解释器不能读取用户其他文件、任意写入外部文件或使用外部管道。通过超时、取消、多消费者复用、损坏输入及缓存失效检查；完成结果原子发布，不用部分 PDF 填充缩略图。真实查看器检查 EPS 3200% 矢量缩放、多页 PS 的上下焦点及左右翻页，以及转换中切换 PNG 后旧结果不会覆盖当前画面。
- Photoshop 格式组新增 `.psb`，与 `.psd` 一同参与文件发现、主图、缩略图及默认打开设置。读取兼容合成图，保留原始画布尺寸；大文件按显示需求生成有界预览。完成 **112 组编码组合、128 组带图层透明标记的结构样例、1 份大幅 PSB、13 份损坏样例**验证。透明合成依据图层计数及 Lr16/Lr32、Mtrn/Mt16/Mt32 标记识别；普通额外 Alpha 通道不会被误当作合成透明度。包含透明像素数值、白色底色去除、编码一致性、大行取消及主图/缩略图集成回归。
- 默认打开弹窗每次打开、应用重新激活、批量设置完成后读取系统实际关联；系统关联本身跨重启保存，不使用未应用草稿冒充成功结果。当前格式全部类型对应当前应用时勾选；仅部分类型命中或指向同 bundle ID 的其他副本时显示横线，并在提示中解释。清空只改变草稿，不撤销系统默认关联。
- 顶部“全选所有格式”一次选中图片、矢量/文档、视频和音频，包含搜索结果之外的格式；仍需点击设置按钮后才写入关联。检测、部分成功、失败读回、重建控制器、草稿与实际状态区别、全量选择均使用内存 mock 后端验证，测试未改变用户系统默认应用。
- 本轮新增设置、PostScript 与 Photoshop 文案覆盖全部 16 种语言，核心文案与格式占位符验证通过。

## 本轮验证

仅计入下面列明且具有完整成功汇总的本轮日志；未重跑的历史模块不加入数量。

| 检查 | 通过 |
| --- | --- |
| PostScript 矢量转换、取消、隔离与实际 EPS | 24 / 24 |
| SVG / EPS 兼容与原附件校验 | 64 / 64 |
| PSD / PSB 合成图、透明通道、大图与损坏数据 | 712 / 712 |
| 默认应用系统读回与批量设置（mock） | 101 / 101 |
| 默认格式弹窗、重开状态与全部格式选择（mock） | 34 / 34 |
| 16 种语言与占位符 | 174 / 174 |
| 发布应用格式声明 | 15 / 15 |
| 图片库与系统解码 | 78 / 78 |
| 画布几何、动画与鼠标 | 66 / 66 |
| 文档解析与完整页绘制 | 56 / 56 |
| 文档焦点、EPS / PS 缩放翻页与取消切文件 | 75 / 75 |
| 真实窗口点击与生命周期 | 65 / 65 |
| 443 文件缩略图、缓存与过期回调 | 37 / 37 |
| 缩略图请求取消与消费者隔离 | 13 / 13 |
| 正式安装发布版右键菜单与私有剪贴板 | 28 / 28 |
| **合计** | **1542 / 1542** |

正式安装的优化发布版另执行 28 项右键菜单检查，通过真实菜单与 target/action 分发，并使用独立命名剪贴板。验证复制图片、视频当前帧、PDF 图片及整页、旋转、切换/关闭时的过期结果处理；测试未覆盖用户系统剪贴板。原有鼠标点击、窗口生命周期、页面焦点、完整页呈现、缩略图缓存与取消回归均通过。

## 发布目录与安装版核验

版本 **1.7.0，build 12**。报告生成前已核对 `outputs/LumaView.app` 和 `/Applications/LumaView.app` 的 bundle ID、版本、build、完整文件清单和 SHA-256；两处应用内容一致。四个可执行文件均通过双架构检查，两处应用通过 `codesign --verify --deep --strict` 验证；内置 Ghostscript 自报版本为 10.08.0，本地化和版本资源与源码目录一致，Ghostscript 源码归档 SHA-256 与附带清单一致。构建时会重新签名解释器，因此不要求签名后的二进制与源码目录内的未重签名副本逐字节相同。

| 可执行文件 | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

本报告不代替随后生成的 ZIP 完整性检查，也不声称进行 Apple 公证。签名为本地临时签名；Apple Silicon 完成交叉编译与架构检查，本轮未在 Apple Silicon 硬件运行。Ghostscript 源码压缩包、许可证与重建说明随源码交付。

## 范围与边界

EPS / PS 中原本嵌入的位图仍受其自身分辨率限制；外部字体或文件资源、特殊或损坏 PostScript 内容不保证能够完整转换。PSD / PSB 预览依赖文件中的兼容合成图，不执行 Photoshop 图层编辑或重建缺失合成图；缺失时提示启用“最大兼容性”后重新保存。原始画布尺寸可大于实际显示预览尺寸，不将有界预览宣称为所有源像素都已完整解码。其他格式边界见 [FORMATS.md](../FORMATS.md)。

## 本轮日志来源

以下文件复制到 `Tests/`，历史未重跑报告仍保留但不计入本轮合计：

- `PostScript-test-results.txt` ← `work/postscript-17/postscript-test-results.txt`
- `vector-compatibility-test-results.txt` ← `work/vector-compatibility-1.7.0/vector-compatibility-test-results.txt`
- `Photoshop-test-results.txt` ← `work/psb-support/results.txt`
- `Default-application-test-results.txt` ← `work/default-application-1.7-results.txt`
- `Default-preferences-test-results.txt` ← `work/default-preferences-tests/default-preferences-test-results.txt`
- `Localization-test-results.txt` ← `work/localization-1.7-results.txt`
- `Media-declaration-test-results.txt` ← `work/media-declaration-1.7.0.txt`
- `Core-test-results.txt` ← `work/core-1.7.0-run.log`
- `Canvas-test-results.txt` ← `work/canvas-1.7.0-run.log`
- `Document-core-test-results.txt` ← `work/document-1.7.0/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-1.7.0/document-test-results.txt`
- `UI-test-results.txt` ← `work/ui-1.7.0/ui-test-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.0/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.0-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.0/context-menu-test-results.txt`
