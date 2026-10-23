# Ghostscript 文档转换工具

<!-- doc-navigation:start -->
[文档目录](../INDEX.md) · **简体中文** · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView 将 Artifex 于 2026-09-08 发布的 Ghostscript **10.08.0** 作为独立本地可执行文件调用，把 EPS 和 PostScript 转为临时 PDF。PDF 输出保留支持的矢量路径、文字和渐变；原本以栅格像素嵌入的图像仍为栅格图。Ghostscript 不链接进 Swift 应用，运行随附程序也无需 Homebrew。

## 许可证与对应源码

此版本的原始 `LICENSE` 文件规定 Ghostscript 按 **GNU Affero General Public License 第 3 版或更新版本**分发。完整许可证、Ghostscript 版权声明、字体嵌入例外、Adobe CMap 声明及随附依赖的声明均原样复制到 `Resources/ThirdPartyNotices/Ghostscript/`。Artifex 另行提供商业许可证；此软件包不包含商业许可证。参见[官方许可证页面](https://www.ghostscript.com/licensing/index.html)。

准确对应且未经修改的源码发行版（含随附依赖与字体源码）位于 `ThirdParty/sources/ghostscript-10.08.0.tar.xz`。其 SHA-256 记录在 `ThirdParty/sources/SHA256SUMS-Ghostscript`：

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

源码来源：[官方发行页面](https://www.ghostscript.com/releases/index.html)及 [Artifex 的 10.08.0 发行资产](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080)。校验值与该 `.tar.xz` 资产公布的校验值一致。源码包和此构建脚本随 LumaView 源码一起分发。LumaView 不对修改或替换这个独立工具，或为调试此类修改所需的逆向工程施加额外限制。这些声明描述随附的第三方组件，并不重新授权应用本身的源码。

## 重新构建

需要 macOS、Xcode Command Line Tools、随附源码归档和标准 macOS 构建工具。不使用 Homebrew 库。从 LumaView 源码目录运行：

```sh
./tools/build-document-tools.sh
./build.sh
```

脚本核验源码归档，分别在两个源码目录中构建 Intel 和 Apple Silicon 分片，移除本地符号，再合并为 `Resources/DocumentTools/gs`。两个分片均以 macOS 13.0 或更新版本为目标。它不执行 `make install`，也不写入系统包管理器。通过 `LUMAVIEW_DOCUMENT_BUILD` 指定中间构建目录，`LUMAVIEW_DOCUMENT_JOBS` 控制 make 并行度（默认 4）。可选参数 `x86_64` 或 `arm64` 只构建单一架构。应用构建会连同应用一起签署复制进去的可执行文件。

可执行文件把初始化代码、随附字体、Adobe CMap 和 ICC 配置内置在 `%rom%` 文件系统中。外部默认搜索路径为空。只启用 `pdfwrite` 输出设备。打印/CUPS、X11、GTK、fontconfig、D-Bus、Tesseract/OCR、动态驱动、外部 IJS 和文档提取工具均已禁用。所有随附的解码、颜色与字体库均从对应源码归档编译；动态链接仅限 Apple 系统库。ROM 文件系统及交叉编译机制见[官方构建文档](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html)。

LumaView 启动解释器时使用 `-dSAFER`、指定输入与输出文件、专用临时工作目录、取消机制和超时。进程环境不能继承用户指定的 Ghostscript 选项或库路径。以下是为生成的可信测试样例提供的命令示例：

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

完整构建选项见 `tools/build-document-tools.sh`，源码归档未打补丁。只有构建主机支持的架构才能原生运行。发布检查会审视两个 Mach-O 分片，并在主机兼容分片中运行包含路径和文字的生成 EPS，确认输出 PDF 仍含矢量绘图和文字操作符。
