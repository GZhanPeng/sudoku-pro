import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/game_controller.dart';
import '../logic/logical_solver.dart';
import '../persistence/saved_game_repository.dart';
import '../settings/app_settings.dart';
import 'settings_screen.dart';
import 'sudoku_grid.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    this.title,
    this.saveProgress = true,
    this.practiceSummary,
    this.onPracticeCompleted,
  });

  final GameController controller;
  final String? title;
  final bool saveProgress;
  final String? practiceSummary;
  final VoidCallback? onPracticeCompleted;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _savedGames = SavedGameRepository();
  late final FocusNode _keyboardFocus;
  late final Timer _clockTimer;
  late bool _wasComplete;
  bool _completionDialogScheduled = false;
  int _lastAutosaveSecond = -1;
  bool _practiceRecorded = false;

  GameController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _keyboardFocus = FocusNode(debugLabel: 'sudoku-keyboard');
    _wasComplete = controller.isComplete;
    controller.addListener(_handleControllerChanged);
    if (widget.saveProgress) _saveProgress();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || controller.isPaused || controller.isComplete) return;
      setState(() {});
      final elapsedSecond = controller.elapsed.inSeconds;
      if (widget.saveProgress &&
          elapsedSecond > 0 &&
          elapsedSecond % 10 == 0 &&
          elapsedSecond != _lastAutosaveSecond) {
        _lastAutosaveSecond = elapsedSecond;
        _saveProgress();
      }
    });
  }

  void _saveProgress() => _savedGames.save(controller);

  void _handleControllerChanged() {
    if (widget.saveProgress) _saveProgress();
    if (controller.practiceCompleted && !_practiceRecorded) {
      _practiceRecorded = true;
      widget.onPracticeCompleted?.call();
    }
    final completed = controller.isComplete;
    if (completed && !_wasComplete && !_completionDialogScheduled) {
      _completionDialogScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCompletionDialog();
      });
    }
    _wasComplete = completed;
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    controller.removeListener(_handleControllerChanged);
    if (widget.saveProgress) _saveProgress();
    _keyboardFocus.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _showCompletionDialog() async {
    _completionDialogScheduled = false;
    if (!mounted || !controller.isComplete) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.emoji_events_outlined, size: 40),
        title: const Text('完成了！', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.difficulty == null
                  ? '经典 9×9'
                  : '经典 9×9 · ${controller.difficulty!.label}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _CompletionStat(
                  icon: Icons.timer_outlined,
                  label: '用时',
                  value: _formatElapsed(controller.elapsed),
                ),
                _CompletionStat(
                  icon: Icons.lightbulb_outline,
                  label: '提示',
                  value: '${controller.hintUseCount} 次',
                ),
                _CompletionStat(
                  icon: Icons.auto_fix_high,
                  label: '清扫',
                  value: '${controller.basicSweepUseCount} 次',
                ),
              ],
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('查看完成盘面'),
          ),
        ],
      ),
    );
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

  Future<void> _showKeyboardHelp() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('电脑快捷键'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('方向键　移动选中格'),
          Text('1–9　填写数字或候选'),
          Text('Delete / Backspace　清除'),
          Text('N　切换数字与候选模式'),
          Text('Ctrl/⌘ + Z　撤销'),
          Text('Ctrl/⌘ + Shift + Z　重做'),
          Text('Space / P　暂停或继续'),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    ),
  );

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (ModalRoute.of(context)?.isCurrent != true) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyP) {
      controller.togglePause();
      return KeyEventResult.handled;
    }
    if (controller.isPaused) return KeyEventResult.handled;

    final keyboard = HardwareKeyboard.instance;
    final commandPressed = keyboard.isControlPressed || keyboard.isMetaPressed;
    if (commandPressed && key == LogicalKeyboardKey.keyZ) {
      if (keyboard.isShiftPressed) {
        controller.redo();
      } else {
        controller.undo();
      }
      return KeyEventResult.handled;
    }
    if (commandPressed && key == LogicalKeyboardKey.keyY) {
      controller.redo();
      return KeyEventResult.handled;
    }

    final digit = int.tryParse(event.character ?? '');
    if (digit != null && digit >= 1 && digit <= 9) {
      controller.enterDigit(digit);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      controller.clearSelected();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyN) {
      controller.toggleNoteMode();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      controller.moveSelection(rowDelta: -1, columnDelta: 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      controller.moveSelection(rowDelta: 1, columnDelta: 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      controller.moveSelection(rowDelta: 0, columnDelta: -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      controller.moveSelection(rowDelta: 0, columnDelta: 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ??
              (controller.difficulty == null
                  ? '经典 9×9'
                  : '经典 9×9 · ${controller.difficulty!.label}'),
        ),
        actions: [
          if (AppSettingsScope.maybeOf(context) != null)
            IconButton(
              tooltip: '设置',
              icon: const Icon(Icons.tune),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset_candidates') {
                _confirmCandidateReset();
              } else if (value == 'keyboard_help') {
                _showKeyboardHelp();
              }
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: 'reset_candidates',
                child: ListTile(
                  leading: Icon(Icons.restart_alt),
                  title: Text('重置全部候选'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'keyboard_help',
                child: ListTile(
                  leading: Icon(Icons.keyboard_outlined),
                  title: Text('电脑快捷键'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Focus(
          autofocus: true,
          focusNode: _keyboardFocus,
          onKeyEvent: _handleKeyEvent,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return _WideGameLayout(
                      controller: controller,
                      practiceSummary: widget.practiceSummary,
                    );
                  }
                  return _CompactGameLayout(
                    controller: controller,
                    practiceSummary: widget.practiceSummary,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CompactGameLayout extends StatelessWidget {
  const _CompactGameLayout({required this.controller, this.practiceSummary});

  final GameController controller;
  final String? practiceSummary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = (constraints.maxWidth - 20).clamp(0.0, 660.0);
        // Keep the whole board visible before the scrollable controls, including
        // in a narrow desktop browser. The panel lays out its actual status and
        // legend heights before fitting the square board into the remaining area.
        final panelHeight = (contentWidth + 120)
            .clamp(0.0, (constraints.maxHeight - 4).clamp(0.0, double.infinity))
            .toDouble();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 660),
              child: Column(
                children: [
                  SizedBox(
                    height: panelHeight,
                    child: _BoardPanel(controller: controller),
                  ),
                  if (practiceSummary != null) ...[
                    const SizedBox(height: 12),
                    _PracticeGuide(
                      controller: controller,
                      summary: practiceSummary!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (controller.hasHint) ...[
                    const SizedBox(height: 12),
                    _HintPanel(controller: controller),
                  ],
                  const SizedBox(height: 12),
                  _ControlPanel(controller: controller, actionColumns: 3),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WideGameLayout extends StatelessWidget {
  const _WideGameLayout({required this.controller, this.practiceSummary});

  final GameController controller;
  final String? practiceSummary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _BoardPanel(controller: controller)),
              const SizedBox(width: 24),
              SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    children: [
                      if (practiceSummary != null) ...[
                        _PracticeGuide(
                          controller: controller,
                          summary: practiceSummary!,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _ControlPanel(controller: controller, actionColumns: 2),
                      if (controller.hasHint) ...[
                        const SizedBox(height: 12),
                        _HintPanel(controller: controller),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardPanel extends StatelessWidget {
  const _BoardPanel({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _StatusBar(controller: controller),
      const SizedBox(height: 12),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.biggest.shortestSide
                .clamp(0.0, 680.0)
                .toDouble();
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox.square(
                dimension: side,
                child: _PausableBoard(controller: controller),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      const _ValueLegend(),
    ],
  );
}

class _PracticeGuide extends StatelessWidget {
  const _PracticeGuide({required this.controller, required this.summary});
  final GameController controller;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.practiceCompleted
                ? '已完成本次技巧练习'
                : '本次目标 · ${controller.practiceTarget?.label}',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(summary),
          const SizedBox(height: 10),
          Text(
            controller.practiceCompleted
                ? '可以撤销并自行重试，或返回练习页选择其他技巧。'
                : '① 提示：观察区域　② 说明结构：理解推理　③ 执行这一步：完成练习',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: controller.isComplete
            ? colors.tertiaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            controller.isComplete
                ? Icons.check_circle_outline
                : Icons.info_outline,
            size: 19,
            color: controller.isComplete
                ? colors.onTertiaryContainer
                : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.statusMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (AppSettingsScope.preferencesOf(context).showTimer) ...[
            Icon(
              Icons.timer_outlined,
              size: 17,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _formatElapsed(controller.elapsed),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          IconButton(
            tooltip: controller.isPaused ? '继续计时' : '暂停计时',
            visualDensity: VisualDensity.compact,
            onPressed: controller.isComplete ? null : controller.togglePause,
            icon: Icon(
              controller.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _PausableBoard extends StatelessWidget {
  const _PausableBoard({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        AbsorbPointer(
          absorbing: controller.isPaused,
          child: Opacity(
            opacity: controller.isPaused ? 0.08 : 1,
            child: SudokuGrid(controller: controller),
          ),
        ),
        if (controller.isPaused)
          ColoredBox(
            color: colors.surface.withValues(alpha: 0.94),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pause_circle_outline,
                    size: 52,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '已暂停',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '盘面已隐藏，计时已停止',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: controller.togglePause,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('继续游戏'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({required this.controller, required this.actionColumns});

  final GameController controller;
  final int actionColumns;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = controller.selectedIndex;
    final selectedLabel = selected == null
        ? '尚未选择格子'
        : 'r${selected ~/ 9 + 1}c${selected % 9 + 1}';
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '输入方式',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    selectedLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.dialpad_outlined),
                    label: Text('填数字'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.edit_note),
                    label: Text('手动候选'),
                  ),
                ],
                selected: {controller.noteMode},
                showSelectedIcon: false,
                onSelectionChanged: controller.isPaused
                    ? null
                    : (selection) {
                        if (selection.first != controller.noteMode) {
                          controller.toggleNoteMode();
                        }
                      },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.noteMode
                  ? '点数字可添加或取消任意小候选，包括试填的错误候选；全标是另一项自动操作。'
                  : '点数字填写大数字；出现行、列、宫冲突时标红，方便试错。',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _NumberPad(controller: controller),
            const SizedBox(height: 12),
            _ActionBar(controller: controller, columns: actionColumns),
            const SizedBox(height: 10),
            Text(
              '方向键移动 · 1–9 输入 · N 候选 · Space 暂停',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
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
                onPressed: controller.isPaused
                    ? null
                    : () => controller.enterDigit(digit),
                style: FilledButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: TextStyle(
                    fontFamily: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.fontFamily,
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
  const _ActionBar({required this.controller, required this.columns});

  final GameController controller;
  final int columns;

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;
    final actions = [
      _ActionButton(
        icon: Icons.undo,
        label: '撤销',
        onPressed: !controller.isPaused && controller.canUndo
            ? controller.undo
            : null,
      ),
      _ActionButton(
        icon: Icons.redo,
        label: '重做',
        onPressed: !controller.isPaused && controller.canRedo
            ? controller.redo
            : null,
      ),
      _ActionButton(
        icon: Icons.backspace_outlined,
        label: '清除',
        onPressed: controller.isPaused ? null : controller.clearSelected,
      ),
      _ActionButton(
        icon: Icons.apps,
        label: '全标',
        selected: controller.candidatesVisible,
        onPressed: controller.isPaused ? null : controller.showAllCandidates,
      ),
      _ActionButton(
        icon: Icons.auto_fix_high,
        label: '基础清扫',
        prominent: true,
        onPressed: controller.isPaused ? null : controller.applyBasicSweep,
      ),
      _ActionButton(
        icon: Icons.lightbulb_outline,
        label: '提示',
        selected: controller.hasHint,
        onPressed: controller.isPaused ? null : controller.requestHint,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(width: buttonWidth, child: action),
          ],
        );
      },
    );
  }
}

class _ValueLegend extends StatelessWidget {
  const _ValueLegend();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 5,
      children: [
        _DotLegend(color: colors.onSurface, label: '题目'),
        _DotLegend(color: colors.primary, label: '你的填数'),
        const _DotLegend(color: Color(0xFF2E7D5B), label: '自动填写'),
        _DotLegend(color: colors.error, label: '冲突'),
      ],
    );
  }
}

class _DotLegend extends StatelessWidget {
  const _DotLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _CompletionStat extends StatelessWidget {
  const _CompletionStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(height: 5),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatElapsed(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
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
            if (explained &&
                (step.chainNodes.isNotEmpty ||
                    step.chainGroups.isNotEmpty ||
                    step.chainCells.isNotEmpty)) ...[
              const SizedBox(height: 10),
              Text(
                step.technique == LogicalTechnique.alsXZ ||
                        step.technique == LogicalTechnique.doublyLinkedAlsXZ
                    ? 'ALS 单元格'
                    : step.isLoop
                    ? '闭环顺序'
                    : '链条顺序',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (step.chainNodes.isNotEmpty)
                    for (var index = 0; index < step.chainNodes.length; index++)
                      ActionChip(
                        key: ValueKey(
                          'hint-node-$index-${step.chainNodes[index].index}-${step.chainNodes[index].digit}',
                        ),
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '${_circledNumber(index)}${index == 0
                              ? step.isLoop
                                    ? ' 闭环起点'
                                    : ' 链头'
                              : !step.isLoop && index == step.chainNodes.length - 1
                              ? ' 链尾'
                              : ''}  (${step.chainNodes[index].digit})r${step.chainNodes[index].index ~/ 9 + 1}c${step.chainNodes[index].index % 9 + 1}',
                        ),
                        onPressed: () =>
                            controller.selectCell(step.chainNodes[index].index),
                      )
                  else if (step.chainGroups.isNotEmpty)
                    for (
                      var index = 0;
                      index < step.chainGroups.length;
                      index++
                    )
                      ActionChip(
                        key: ValueKey(
                          'hint-group-$index-${step.chainGroups[index].first.index}-${step.chainGroups[index].first.digit}',
                        ),
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '${_circledNumber(index)}${index == 0
                              ? step.isLoop
                                    ? ' 闭环起点'
                                    : ' 链头'
                              : !step.isLoop && index == step.chainGroups.length - 1
                              ? ' 链尾'
                              : ''}  (${step.chainGroups[index].first.digit})${step.chainGroups[index].map((candidate) => 'r${candidate.index ~/ 9 + 1}c${candidate.index % 9 + 1}').join('/')}${step.chainGroups[index].length > 1 ? ' 组' : ''}',
                        ),
                        onPressed: () => controller.selectCell(
                          step.chainGroups[index].first.index,
                        ),
                      )
                  else
                    for (var index = 0; index < step.chainCells.length; index++)
                      ActionChip(
                        key: ValueKey(
                          'hint-cell-$index-${step.chainCells[index]}',
                        ),
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '${_circledNumber(index)}  r${step.chainCells[index] ~/ 9 + 1}c${step.chainCells[index] % 9 + 1}',
                        ),
                        onPressed: () =>
                            controller.selectCell(step.chainCells[index]),
                      ),
                ],
              ),
            ],
            if (explained && step.links.any((link) => link.reason != null)) ...[
              const SizedBox(height: 10),
              Text(
                '连接依据',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              for (var index = 0; index < step.links.length; index++)
                if (step.links[index].reason case final reason?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '${index + 1}. ${step.links[index].strength == LogicalLinkStrength.strong ? '强链' : '弱链'} · $reason',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
            ],
            if (explained &&
                (step.links.isNotEmpty || step.groupLinks.isNotEmpty)) ...[
              const SizedBox(height: 10),
              _ChainLegend(
                colors: colors,
                showsCandidateColors: step.candidateColors.isNotEmpty,
              ),
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

  String _circledNumber(int index) {
    const labels = [
      '①',
      '②',
      '③',
      '④',
      '⑤',
      '⑥',
      '⑦',
      '⑧',
      '⑨',
      '⑩',
      '⑪',
      '⑫',
      '⑬',
      '⑭',
      '⑮',
      '⑯',
      '⑰',
      '⑱',
      '⑲',
      '⑳',
    ];
    return index < labels.length ? labels[index] : '${index + 1}.';
  }
}

class _ChainLegend extends StatelessWidget {
  const _ChainLegend({
    required this.colors,
    required this.showsCandidateColors,
  });

  final ColorScheme colors;
  final bool showsCandidateColors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _LegendItem(color: colors.primary, label: '实线：强链'),
        _LegendItem(color: colors.secondary, label: '虚线：弱链', dashed: true),
        if (showsCandidateColors) ...[
          const _LegendItem(color: Color(0xFF1565C0), label: '蓝色：染色 A'),
          const _LegendItem(color: Color(0xFFEF6C00), label: '橙色：染色 B'),
        ],
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
