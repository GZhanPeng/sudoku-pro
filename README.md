# 数独助手

经典 9×9 数独工具，首发面向 Web/PWA。纸质风格，支持本机保存和离线使用。

## 功能

- 六档难度出题、手动录入与唯一解验证。
- 自由填数、手动候选、自动全标、候选排除；行列宫冲突标红。
- 同数候选用无边框的小方块强调，完整棋盘随窗口宽高缩放。
- 基础清扫、分步逻辑提示、链与结构可视化、撤销与重做。
- 21 种技巧练习，支持分类、搜索和独立完成记录。
- 深浅色、候选字号、解题计时和暂停等设置。
- 网页版在当前浏览器保存最近一局、设置和练习记录；无需账户。

网页版照片导入用于参照图片手动录入，不进行自动 OCR。原生工程和本地 OCR 代码保留，但不属于首发验收范围；原生版本尚未实现持久存档。

## 本机运行

macOS 双击 `start_sudoku.command`，或运行：

```bash
./start_sudoku.command
```

脚本使用 `/Users/guo/.local/share/flutter`，必要时自动构建，在 `http://127.0.0.1:8787/` 启动网页。使用期间保持终端打开，按 Control+C 停止。

## 检查与构建

将 Flutter 加入 PATH 后执行：

```bash
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-web-resources-cdn --no-pub
```

将 `build/web/` 整个目录部署到 HTTPS 地址，便可按浏览器提示安装到桌面或主屏幕。成功缓存后可离线启动；本机默认关闭 service worker，使用 `/?pwa-test` 可启用离线缓存测试。

OCR 模型只随原生版本打包，网页发布包不包含模型。模型来源和许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 目录

- `lib/src/logic/`：出题、唯一解检查、逻辑求解和练习题。
- `lib/src/controller/`、`model/`：盘面状态、候选、历史记录。
- `lib/src/ui/`、`settings/`：界面和偏好设置。
- `lib/src/persistence/`、`platform/`：存档和平台适配。
- `lib/src/ocr/`、`assets/models/`：原生 OCR。
- `test/`：逻辑、存档、交互和渲染回归测试。
- `web/`：PWA 入口、图标和离线缓存。
- `android/`、`ios/`、`macos/`：保留的原生工程。

`build/` 与 `.dart_tool/flutter_build/` 为生成产物，不属于源码。清理构建与编译缓存不会删除当前浏览器中的存档；再次检查或构建时，Flutter 会重新生成所需缓存。
