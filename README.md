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
  - 中等：加入显性/隐性二至四数组和 X-Wing
  - 困难：加入 Swordfish、唯一矩形、BUG+1、翼和典型短链
  - 专家：加入 Jellyfish、Finned X-Wing、简单染色、Remote Pairs 和 X/XY-Chain
  - 骨灰：加入 X-Cycle、Nice Loop、AIC、Grouped AIC/Loop 和 ALS-XZ
- 每道生成题都经过唯一解检查和逻辑求解验证
- 唯一矩形和 BUG+1 仅用于已经通过唯一解验证的题目
- 全标所有合法候选数
- 合法候选与人工排除分开保存，不会重新加入手动删掉的候选
- 候选模式下逐个添加或排除候选
- 点击已填数字或在候选模式输入数字时，同时追踪同数候选；设置可选仅高亮候选数字、连同所在格子高亮，或关闭候选高亮
- 手动候选允许自由填写；与行、列、宫中已填数字冲突时标红，冲突解除后恢复普通颜色
- 非给定格允许试填任意 1–9，不会偷看最终答案拦截输入；行、列、宫重复时只标红提醒
- 一键“基础清扫”
  - 唯余法（Naked Single）
  - 行、列、宫摒除法（Hidden Single）
  - 循环执行直到两种基础技巧都无法继续
- 清扫前检查人工候选是否与唯一解矛盾
- 撤销与重做；基础清扫整批作为一个历史步骤
- 解题计时与暂停，暂停时隐藏盘面；时间和辅助次数随进度保存
- 完成弹窗汇总用时、提示次数和基础清扫次数
- 电脑键盘操作：方向键移动、1–9 输入、N 切换候选、Delete 清除、快捷键撤销/重做
- 渐进式“下一步提示”
  - 第一次只高亮应该观察的区域
  - 第二层解释技巧、结构和结论
  - 链类技巧使用实线显示强链、虚线显示弱链
  - Remote Pairs、X/XY-Chain 和 AIC 在棋盘上按推导顺序编号，并突出链头、链尾
  - X-Cycle 与 Nice Loop 显示完整闭合边，区分“闭环起点”与普通链首尾
  - Grouped AIC/Loop 将同一宫线交叉区内的多个候选合并为组节点并编号
  - ALS-XZ 用蓝/橙两色标出两个几乎锁定集，支持单 RCC 与双 RCC
  - 简单染色使用蓝/橙两色区分候选，红色标出可删候选
  - 点击链条坐标可直接聚焦到对应棋格
  - 需要时可代为执行一步，并可撤销
- 高阶提示通过真实难题回归逐步校验，不会删除唯一解中的正确候选
- 提示覆盖唯余、宫行列摈除、区块摈除、显性/隐性二至四数组、X-Wing、Swordfish、Jellyfish、Finned X-Wing、唯一矩形 Type 1/2/3/4、BUG+1、摩天楼、双线风筝、空矩形、W-Wing、XY-Wing、XYZ-Wing、简单染色、Remote Pairs、X/XY-Chain、X-Cycle、不连续/连续 Nice Loop、AIC Type 1/2、Grouped AIC Type 1/2、组节点 Nice Loop、ALS-XZ 与双链 ALS-XZ
- 内置 21 种技巧练习，分为基础候选、鱼与翼、链与闭环、几乎锁定集；支持搜索、学习目标和练习完成记录，练习局不会覆盖正常游戏进度
- 练习自动准备必要的前置逻辑与候选状态，提示优先展示目标技巧；包含 X/XY-Chain、AIC、Grouped AIC Type 1/2、Nice Loop 和单/双链 ALS-XZ
- 纸质风格界面，支持跟随系统、浅色与深色模式
- 桌面端棋盘与提示面板独立滚动，阅读长提示时可保持盘面位置
- 设置候选字号、相关棋格与同数高亮、候选冲突提醒、用时显示、偏好难度与新题自动全标；网页版在本机保存设置与练习完成记录
- 基础辅助功能标签
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
├── controller/   游戏状态、候选排除、计时、撤销与重做
├── logic/        唯一解、出题、难度评级、基础与进阶逻辑技巧
├── model/        9×9 盘面模型
├── ocr/          本地 YOLO/TFLite 识别
└── ui/           首页、校对页、游戏盘面
```

## 第三方模型

OCR 模型来源、许可和发布注意事项见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。当前模型只按私人自用场景接入；公开分发前需要重新审视 AGPL-3.0 许可或更换模型。
