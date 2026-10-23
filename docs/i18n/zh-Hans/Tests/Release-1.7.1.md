> 历史验证记录中的个人样本文件名已匿名化；测试数据与结果保持原样。

<!-- doc-navigation:start -->
[文档目录](../INDEX.md) · **简体中文** · [繁體中文](../../zh-Hant/Tests/Release-1.7.1.md) · [English](../../en/Tests/Release-1.7.1.md) · [日本語](../../ja/Tests/Release-1.7.1.md) · [한국어](../../ko/Tests/Release-1.7.1.md) · [Français](../../fr/Tests/Release-1.7.1.md) · [Deutsch](../../de/Tests/Release-1.7.1.md) · [Español](../../es/Tests/Release-1.7.1.md) · [Italiano](../../it/Tests/Release-1.7.1.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.1.md) · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · [Türkçe](../../tr/Tests/Release-1.7.1.md) · [Nederlands](../../nl/Tests/Release-1.7.1.md) · [Polski](../../pl/Tests/Release-1.7.1.md)
<!-- doc-navigation:end -->

# LumaView 1.7.1 验证记录

版本 1.7.1，build 13。2026-10-22，macOS 15.7.9 / Intel。应用及三个内置工具通过 arm64 + x86_64 架构与本地签名核验；本轮未在 Apple Silicon 硬件运行。

## 已定位并修复

用户的三个 PSB 均为 8 位 RGB、4 通道、带合成透明的 RLE 文件，约 108–123 MiB。大部分文件体积属于可直接跳过的图层数据；主画布约 850–960 万像素。

1. 旧逐行解码器为每个 PackBits 标记和值调用 FileHandle 读取，产生大量小读取，令主图和缩略图队列停留过久。改为最多 64 KiB 分块读取，保留跨块 literal/run 状态及边界检查，长 no-op 数据仍可取消。ZIP 仅对采样到的行恢复预测，仍完整校验压缩流。
2. 三个文件都带有资源 1036 的有效 RGB JPEG 缩略图。现在胶片带优先使用它，校验格式、尺寸、长宽比及压缩长度；主图始终解码真正的合成图。无效预览、旧式 BGR 资源或无预览时回退到合成图。
3. 系统 ImageIO 会拒绝部分带有效 Generic RGB ICC 的小尺寸 PSD 合成数据，旧版因而返回空缩略图。回退时分开解码像素，再附加经验证且颜色模型、分量一致的原 ICC，不直接丢弃配置。原文件 ICC 与系统标准 Generic RGB Profile 相同，新增回归使用系统配置生成测试数据，未将用户照片写入源码。
4. PSB 主图复用已经解析的头信息，并避免额外调用 ImageIO 扫描图层取元数据。原始尺寸、透明度和主图质量保留。

## 三个原文件实测

以下为这台 Mac 的本地测试，受系统负载与文件缓存影响，不是所有设备的性能保证。旧解码与新解码均使用优化编译。

| 文件 | 原始尺寸 | 旧主图解码 | 新主图解码 | 新合成图缩略解码（无内嵌预览路径） |
| --- | --- | --- | --- | --- |
| Sample A | 2582 × 3318 | 超过 15 秒后测试主动取消 | 0.68 秒 | 0.039 秒 |
| Sample B | 2610 × 3307 | 14.35 秒 | 0.65 秒 | 0.028 秒 |
| Sample C | 2843 × 3361 | 超过 15 秒后测试主动取消 | 0.70 秒 | 0.028 秒 |

通过真实 ImageLoader 同时请求三张缩略图，约 0.06 秒全部完成。完整主图经加载器分别约 0.90 / 0.65 / 0.74 秒。旧版三张合成缩略图均报 unsupported；新版本均成功。原件在测试前后逐字节 SHA-256 一致，应用没有写入原文件。

## 本轮通过的检查

| 项目 | 结果 |
| --- | --- |
| PSD / PSB 编码与透明合成 | 712 / 712 |
| RLE 性能、内嵌预览、ICC、跨块与取消 | 54 / 54 |
| 三个原始 PSB 的真实 ImageLoader 集成 | 21 / 21 |
| 443 文件胶片带、缓存、失效回调 | 37 / 37 |
| 独立缩略图请求与取消 | 13 / 13 |
| 图片库与系统解码 | 78 / 78 |
| 已安装优化发布版右键菜单与复制 | 28 / 28 |
| 合计 | 943 / 943 |

新增测试覆盖密集单字节 literal、64 KiB 边界、长 no-op 取消、截断与越界、内嵌缩略图与主图各自正确内容、ICC、透明度、小尺寸非整数缩放。既有 112 个编码组合、128 个带图层透明标志的结构样例继续通过。缩略图条检查覆盖快速切换、离屏取消和旧回调不污染当前列表。

正式安装版与 outputs/LumaView.app 完整文件清单和哈希一致，均通过 codesign --verify --deep --strict。安装前保留旧版 ZIP 备份；未修改默认打开关联。ZIP 交付包另行执行 CRC 和版本校验。历史 1.7.0 完整报告保留在 Tests/Release-1.7.0.md，其未重跑检查不计入本轮。

主程序 SHA-256：`cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`。

## 日志

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
