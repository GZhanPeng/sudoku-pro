# 数独助手

一个面向经典 9×9 数独的私人解题工具。它自动清理重复性的基础步骤，同时保留链、翼、鱼等高阶结构给使用者自行观察。

## 已完成

- 拍照或相册导入入口
- 完全在设备本地运行的棋盘检测与数字识别
- OCR 结果逐格校对，低置信度和行列宫冲突标红
- 手动录入与唯一解验证
- 自动生成新题，按人类解法中最难的一步划分难度，而不是只按给定数数量
  - 入门：唯余与宫行列摈除
  - 简单：加入区块摈除和显性数对
  - 中等：加入数组、隐性数对和 X-Wing
  - 困难：加入翼、短链和分组结构
- 每道生成题都经过唯一解检查和逻辑求解验证
- 全标所有合法候选数
- 合法候选与人工排除分开保存，不会重新加入手动删掉的候选
- 候选模式下逐个添加或排除候选
- 非给定格允许试填任意 1–9，不会偷看最终答案拦截输入；行、列、宫重复时只标红提醒
- 一键“基础清扫”
  - 唯余法（Naked Single）
  - 行、列、宫摒除法（Hidden Single）
  - 循环执行直到两种基础技巧都无法继续
- 清扫前检查人工候选是否与唯一解矛盾
- 一次撤销整批基础清扫
- 渐进式“下一步提示”
  - 第一次只高亮应该观察的区域
  - 第二层解释技巧、结构和结论
  - 链类技巧使用实线显示强链、虚线显示弱链
  - 需要时可代为执行一步，并可撤销
- 提示覆盖唯余、宫行列摈除、区块摈除、显性/隐性数组、X-Wing、摩天楼、双线风筝、空矩形、W-Wing 和 XY-Wing
- 内置技巧练习：自动完成前置逻辑，让 X-Wing、摩天楼、双线风筝、空矩形、W-Wing 或 XY-Wing 恰好成为下一步；练习局不会覆盖正常游戏进度
- 深色模式和基础辅助功能标签
- PWA 安装，支持 Android、iPhone/iPad、Windows、macOS 和 Linux
- 首次联网加载后可离线启动
- 网页版在浏览器本机自动保存最近的解题进度

## 运行环境

Flutter SDK 位于：

```text
/Users/guo/.local/share/flutter
```

当前主要目标是跨平台 PWA，不需要 Android Studio 或 Xcode。如以后需要原生安装包，再补齐移动端工具链：

- iPhone/iPad：完整 Xcode + CocoaPods
- Android：Android Studio + Android SDK

### 一键启动（macOS）

在 Finder 中双击项目根目录的 `start_sudoku.command`，或在终端执行：

```bash
./start_sudoku.command
```

脚本会启动无调试连接的本机网页版并自动打开 Chrome，避免 Flutter 调试 WebSocket 受防火墙或代理影响。如果代码有更新，它会先自动构建最新版本。

临时配置国内镜像并运行测试：

```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

/Users/guo/.local/share/flutter/bin/flutter test
/Users/guo/.local/share/flutter/bin/flutter analyze
```

浏览器预览：

```bash
/Users/guo/.local/share/flutter/bin/flutter run -d chrome
```

浏览器版支持手动录入、照片参照录入和完整解题流程。现有 TFLite OCR 只在原生移动端启用，网页端自动识别需要在下一阶段转换模型或接入服务端。

## PWA 发布构建

```bash
/Users/guo/.local/share/flutter/bin/flutter build web --release --no-web-resources-cdn
```

构建结果位于 `build/web/`。部署时需要 HTTPS，并将整个目录原样上传；`sw.js` 会在第一次成功访问后缓存应用核心文件和浏览器渲染资源。

## 目录

```text
lib/src/
├── controller/   游戏状态、候选排除、撤销
├── logic/        唯一解、出题、难度评级、基础与进阶逻辑技巧
├── model/        9×9 盘面模型
├── ocr/          本地 YOLO/TFLite 识别
└── ui/           首页、校对页、游戏盘面
```

## 第三方模型

OCR 模型来源、许可和发布注意事项见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。当前模型只按私人自用场景接入；公开分发前需要重新审视 AGPL-3.0 许可或更换模型。
