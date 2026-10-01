import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controller/game_controller.dart';
import '../logic/logical_solver.dart';
import '../logic/puzzle_generator.dart';
import '../model/sudoku_board.dart';
import '../persistence/saved_game_repository.dart';
import 'game_screen.dart';
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        Align(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              Icons.grid_4x4_rounded,
                              size: 48,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '数独助手',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '替你清理基础步骤，把注意力留给链与结构',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const Spacer(),
                        if (_hasSavedGame) ...[
                          FilledButton.tonalIcon(
                            onPressed: () => _resumeSavedGame(context),
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('继续上次解题'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                              : const Icon(Icons.auto_awesome),
                          label: Text(_generating ? '正在出题…' : '自动生成新题'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _openEntry(context, startWithCamera: !kIsWeb),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(kIsWeb ? '导入照片辅助录入' : '拍照导入并校对'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _openEntry(context),
                          icon: const Icon(Icons.dialpad_outlined),
                          label: const Text('手动录入题目'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 14),
                        Card(
                          elevation: 0,
                          color: colors.surfaceContainerHighest.withValues(
                            alpha: 0.55,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '支持全标候选、保留手动排除、一键清扫唯余与行列宫摈除；网页版会在本机保存最近的解题进度。',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(controller: controller),
      ),
    );
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
                    leading: CircleAvatar(child: Text('${item.index + 1}')),
                    title: Text(item.label),
                    subtitle: Text(item.description),
                    trailing: const Icon(Icons.chevron_right),
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
