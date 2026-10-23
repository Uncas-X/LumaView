# 随附的媒体工具

<!-- doc-navigation:start -->
[文档目录](../INDEX.md) · **简体中文** · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · [한국어](../../ko/ThirdParty/README.md) · [Français](../../fr/ThirdParty/README.md) · [Deutsch](../../de/ThirdParty/README.md) · [Español](../../es/ThirdParty/README.md) · [Italiano](../../it/ThirdParty/README.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · [Русский](../../ru/ThirdParty/README.md) · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · [Nederlands](../../nl/ThirdParty/README.md) · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


LumaView 将未经修改的 FFmpeg 9.0.2 和 ffprobe 作为独立本地进程调用。它们由源码构建为 Intel 与 Apple Silicon 通用版本，最低支持 macOS 13；AV1 解码使用静态链接的 dav1d 1.5.3，动态库仅依赖系统组件。运行时不需要 Homebrew 或 VLC。

FFmpeg 按 LGPL 2.1 或更新版本配置，未启用 `--enable-gpl` 或 `--enable-nonfree`。dav1d 使用 BSD 2-Clause 许可证。完整许可证位于 `Resources/ThirdPartyNotices`，并被复制进应用包。`sources/` 中包含准确对应、未经修改的源码归档及其 SHA-256 校验值。全部配置参数和构建步骤见 `tools/build-media-tools.sh`。LumaView 不对修改或替换这些独立工具、或为调试此类修改所需的逆向工程施加额外限制。

官方来源：

- [FFmpeg 发行版及签名](https://ffmpeg.org/download.html)：`https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`。其分离签名已用 FFmpeg 发布密钥 `FCF986EA15E6E293A5644F10B4322F04D67658D8` 核验。
- [dav1d 发行版](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/)：`dav1d-1.5.3.tar.xz`。
- [FFmpeg 许可证信息](https://ffmpeg.org/legal.html)。

## 重新构建

普通应用构建使用随附的通用可执行文件。如需重建这些工具，安装 Xcode Command Line Tools、Python 3、Meson 1.12.1 和 Ninja 1.13.2。例如，在本地 Python 虚拟环境中安装 `meson==1.12.1 ninja==1.13.2`，激活后运行：

```sh
./tools/build-media-tools.sh
./build.sh
```

第一个命令会核验源码校验值、分别编译两种架构，并替换 `Resources/MediaTools/{ffmpeg,ffprobe}`。通过 `LUMAVIEW_PYTHON` 选择 Python，通过 `LUMAVIEW_MEDIA_BUILD` 选择中间构建目录。参数 `x86_64` 或 `arm64` 只构建单一架构；默认参数 `universal` 会合并两个架构。应用构建使用本地临时签名签署嵌套工具和应用。

网络功能、采集设备、ffplay、dav1d 以外的外部解码器及 GPL 编码器均已关闭。此配置可用的所有内置解码器和解封装器均包含在内。音频输出准备为 AAC；视频尽可能重新封装，否则输出 VideoToolbox H.264、MPEG-4 或 ProRes 兼容文件。这是查看时使用的路径，不提供导出或转码界面。

## PostScript 矢量解释器

EPS、PostScript 和旧式 Illustrator 预览另外使用随附的 Ghostscript 10.08.0，以独立、受限的本地子进程运行。其 AGPL-3.0-or-later 许可证、完整对应源码归档、校验值和可复现的通用版本构建步骤见 [README-Ghostscript.md](README-Ghostscript.md)。普通应用构建不需要系统安装 Ghostscript。
