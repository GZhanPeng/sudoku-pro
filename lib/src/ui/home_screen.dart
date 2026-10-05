import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controller/game_controller.dart';
import '../logic/logical_solver.dart';
import '../logic/puzzle_generator.dart';
import '../model/sudoku_board.dart';
import '../persistence/saved_game_repository.dart';
import '../settings/app_settings.dart';
import 'game_screen.dart';
import 'practice_screen.dart';
import 'settings_screen.dart';
import 'puzzle_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const samplePuzzle =
      '530070000'
      '600195000'
      '098000060'
      '800060003'
      '400803001'
      '700020006'
      '060000280'
      '000419005'
      '000080079';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _savedGames = SavedGameRepository();

  bool _hasSavedGame = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _refreshSavedGame();
  }

  void _refreshSavedGame() {
    _hasSavedGame = _savedGames.hasSavedGame;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '经典数独 · 9×9',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        actions: [
          IconButton(
            tooltip: '设置',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.tune),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(
                  '数独助手',
                  style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  '替你清理基础步骤，把注意力留给链与结构',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '留一点时间，解一道题',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '六档难度 · 逐步提示 · 自由标记',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 18),
                        if (_hasSavedGame) ...[
                          OutlinedButton.icon(
                            onPressed: () => _resumeSavedGame(context),
                            icon: const Icon(Icons.play_arrow_outlined),
                            label: const Text('继续上次解题'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        FilledButton.icon(
                          onPressed: _generating
                              ? null
                              : () => _chooseDifficulty(context),
                          icon: _generating
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(_generating ? '正在出题…' : '自动生成新题'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _choosePractice(context),
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('技巧练习'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '从基础候选到链与闭环，每次专注一个技巧',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 22),
                Text('录入自己的题目', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _openEntry(context),
                  icon: const Icon(Icons.dialpad_outlined),
                  label: const Text('手动录入题目'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      _openEntry(context, startWithCamera: !kIsWeb),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(kIsWeb ? '导入照片辅助录入' : '拍照导入并校对'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _openSample(context),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('打开示例盘面'),
                ),
                if (kIsWeb)
                  TextButton.icon(
                    onPressed: () => _showInstallHelp(context),
                    icon: const Icon(Icons.install_desktop_outlined),
                    label: const Text('安装到手机或电脑'),
                  ),
                const SizedBox(height: 8),
                Text(
                  kIsWeb ? '题目进度与设置保存在当前浏览器' : '候选、清扫和提示，按你的节奏使用',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resumeSavedGame(BuildContext context) async {
    final controller = _savedGames.load();
    if (controller == null) {
      setState(_refreshSavedGame);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('保存的进度已失效')));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(controller: controller),
      ),
    );
    if (mounted) setState(_refreshSavedGame);
  }

  Future<void> _openEntry(
    BuildContext context, {
    bool startWithCamera = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleEntryScreen(startWithCamera: startWithCamera),
      ),
    );
    if (mounted) setState(_refreshSavedGame);
  }

  Future<void> _openSample(BuildContext context) async {
    final controller = GameController.fromPuzzle(
      SudokuBoard.parse(HomeScreen.samplePuzzle),
    );
    if (AppSettingsScope.preferencesOf(context).autoCandidates) {
      controller.showAllCandidates();
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(controller: controller),
      ),
    );
    if (mounted) setState(_refreshSavedGame);
  }

  Future<void> _choosePractice(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const PracticeScreen()));
    if (mounted) setState(_refreshSavedGame);
  }

  Future<void> _chooseDifficulty(BuildContext context) async {
    if (_hasSavedGame) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('开始新题？'),
          content: const Text('新题开始后会替换当前保存的解题进度。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('继续'),
            ),
          ],
        ),
      );
      if (replace != true || !context.mounted) return;
    }

    final preferred = AppSettingsScope.preferencesOf(context).defaultDifficulty;
    final difficulty = await showModalBottomSheet<PuzzleDifficulty>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '选择难度',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final item in PuzzleDifficulty.values)
                  ListTile(
                    leading: Icon(
                      item == preferred
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(item.label),
                    subtitle: Text(item.description),
                    trailing: item == preferred
                        ? const Text('偏好')
                        : const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, item),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (difficulty == null || !mounted) return;
    await _generateAndOpen(difficulty);
  }

  Future<void> _generateAndOpen(PuzzleDifficulty difficulty) async {
    setState(() => _generating = true);
    try {
      final payload = await compute(
        _generatePuzzlePayload,
        difficulty.index,
        debugLabel: 'sudoku-generator-${difficulty.name}',
      );
      if (!mounted) return;
      final actualDifficulty =
          PuzzleDifficulty.values[payload['difficulty']! as int];
      final controller = GameController.fromPuzzle(
        SudokuBoard.parse(payload['puzzle']! as String),
        difficulty: actualDifficulty,
      );
      if (AppSettingsScope.preferencesOf(context).autoCandidates) {
        controller.showAllCandidates();
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(controller: controller),
        ),
      );
      if (mounted) setState(_refreshSavedGame);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('出题失败：$error')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _showInstallHelp(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '安装数独助手',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.android),
                title: Text('Android / Chrome'),
                subtitle: Text('打开浏览器菜单，选择“安装应用”或“添加到主屏幕”。'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.phone_iphone),
                title: Text('iPhone / iPad'),
                subtitle: Text('用 Safari 打开，点“分享”，再选“添加到主屏幕”。'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.computer),
                title: Text('Windows / macOS / Linux'),
                subtitle: Text('使用 Chrome 或 Edge 地址栏的安装图标。'),
              ),
              const SizedBox(height: 4),
              const Text('部署到 HTTPS 网址后才会显示正式安装选项。'),
            ],
          ),
        ),
      ),
    );
  }
}

Map<String, Object> _generatePuzzlePayload(int difficultyIndex) {
  const generator = PuzzleGenerator();
  final generated = generator.generate(
    PuzzleDifficulty.values[difficultyIndex],
  );
  return {
    'puzzle': generated.puzzle.encode(),
    'difficulty': generated.difficulty.index,
    'seed': generated.seed,
    'clues': generated.clueCount,
    'steps': generated.logicalStepCount,
  };
}
