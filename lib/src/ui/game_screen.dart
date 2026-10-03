import 'package:flutter/material.dart';

import '../controller/game_controller.dart';
import '../logic/logical_solver.dart';
import '../persistence/saved_game_repository.dart';
import 'sudoku_grid.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _savedGames = SavedGameRepository();

  GameController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_saveProgress);
    _saveProgress();
  }

  void _saveProgress() => _savedGames.save(controller);

  @override
  void dispose() {
    _saveProgress();
    controller.removeListener(_saveProgress);
    controller.dispose();
    super.dispose();
  }

  Future<void> _confirmCandidateReset() async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置全部候选？'),
        content: const Text('这会恢复你通过链或结构手动排除的候选数。普通的全标操作不会恢复它们。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('重置'),
          ),
        ],
      ),
    );
    if (reset == true) {
      controller.showAllCandidates(resetManualEliminations: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.difficulty == null
              ? '经典 9×9'
              : '经典 9×9 · ${controller.difficulty!.label}',
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset_candidates') _confirmCandidateReset();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'reset_candidates',
                child: ListTile(
                  leading: Icon(Icons.restart_alt),
                  title: Text('重置全部候选'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        children: [
                          _StatusBar(controller: controller),
                          const SizedBox(height: 8),
                          AspectRatio(
                            aspectRatio: 1,
                            child: SudokuGrid(controller: controller),
                          ),
                          const SizedBox(height: 16),
                          _NumberPad(controller: controller),
                          const SizedBox(height: 14),
                          _ActionBar(controller: controller),
                          if (controller.hasHint) ...[
                            const SizedBox(height: 12),
                            _HintPanel(controller: controller),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            '自动填写为绿色；你的填数为蓝色；给定数字为黑色。',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: controller.isComplete
            ? colors.tertiaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        controller.statusMessage,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var digit = 1; digit <= 9; digit++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FilledButton.tonal(
                onPressed: () => controller.enterDigit(digit),
                style: FilledButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text('$digit'),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionButton(
          icon: Icons.undo,
          label: '撤销',
          onPressed: controller.canUndo ? controller.undo : null,
        ),
        _ActionButton(
          icon: controller.noteMode ? Icons.edit_note : Icons.edit_outlined,
          label: '候选',
          selected: controller.noteMode,
          onPressed: controller.toggleNoteMode,
        ),
        _ActionButton(
          icon: Icons.apps,
          label: '全标',
          selected: controller.candidatesVisible,
          onPressed: controller.showAllCandidates,
        ),
        _ActionButton(
          icon: Icons.auto_fix_high,
          label: '基础清扫',
          prominent: true,
          onPressed: controller.applyBasicSweep,
        ),
        _ActionButton(
          icon: Icons.lightbulb_outline,
          label: '提示',
          selected: controller.hasHint,
          onPressed: controller.requestHint,
        ),
        _ActionButton(
          icon: Icons.backspace_outlined,
          label: '清除',
          onPressed: controller.clearSelected,
        ),
      ],
    );
  }
}

class _HintPanel extends StatelessWidget {
  const _HintPanel({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final step = controller.hintStep!;
    final explained = controller.hintLevel >= 2;
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.tertiaryContainer.withValues(alpha: 0.72),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  size: 20,
                  color: colors.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    explained ? step.technique.label : '先看哪里',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                ),
                Text(
                  step.difficulty.label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(explained ? step.explanation : step.focus),
            if (explained && step.links.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ChainLegend(colors: colors),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: controller.dismissHint,
                  child: const Text('关闭'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: explained
                      ? controller.applyHintStep
                      : controller.revealHintExplanation,
                  child: Text(explained ? '执行这一步' : '说明结构'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainLegend extends StatelessWidget {
  const _ChainLegend({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _LegendItem(color: colors.primary, label: '实线：强链'),
        _LegendItem(color: colors.secondary, label: '虚线：弱链', dashed: true),
        _LegendItem(color: colors.error, label: '红色：可删候选'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 25,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var index = 0; index < (dashed ? 3 : 1); index++)
                Container(width: dashed ? 6 : 25, height: 2.5, color: color),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.prominent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    if (prominent) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: selected
          ? OutlinedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            )
          : null,
    );
  }
}
