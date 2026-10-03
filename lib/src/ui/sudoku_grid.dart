import 'package:flutter/material.dart';

import '../controller/game_controller.dart';
import '../logic/sudoku_engine.dart';

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.onSurface, width: 2.2),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
        ),
        itemCount: 81,
        itemBuilder: (context, index) =>
            _SudokuCell(index: index, controller: controller),
      ),
    );
  }
}

class _SudokuCell extends StatelessWidget {
  const _SudokuCell({required this.index, required this.controller});

  final int index;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final row = index ~/ 9;
    final column = index % 9;
    final selected = controller.selectedIndex == index;
    final sameValue = controller.hasSameValueAsSelected(index);
    final peer = controller.isPeerOfSelected(index);
    final value = controller.valueAt(index);
    final conflicting = controller.isConflictingCell(index);

    Color background = colors.surface;
    if (peer) background = colors.primaryContainer.withValues(alpha: 0.28);
    if (sameValue) background = colors.secondaryContainer;
    if (selected) background = colors.primaryContainer;
    if (controller.isHintPatternCell(index)) {
      background = colors.tertiaryContainer;
    }
    if (controller.isHintAffectedCell(index)) {
      background = colors.errorContainer.withValues(alpha: 0.72);
    }

    return Semantics(
      label: '第 ${row + 1} 行第 ${column + 1} 列${value == 0 ? '空格' : value}',
      button: true,
      child: InkWell(
        onTap: () => controller.selectCell(index),
        child: Container(
          decoration: BoxDecoration(
            color: background,
            border: Border(
              right: BorderSide(
                color: colors.outline,
                width: column == 2 || column == 5 ? 2 : 0.45,
              ),
              bottom: BorderSide(
                color: colors.outline,
                width: row == 2 || row == 5 ? 2 : 0.45,
              ),
            ),
          ),
          child: value == 0
              ? _CandidateMarks(
                  mask: controller.visibleCandidateMaskAt(index),
                  color: colors.onSurfaceVariant,
                  patternMask: controller.hintPatternMaskAt(index),
                  eliminationMask: controller.hintEliminationMaskAt(index),
                )
              : Center(
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 22,
                      height: 1,
                      fontWeight: controller.isGiven(index)
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: conflicting
                          ? colors.error
                          : controller.isGiven(index)
                          ? colors.onSurface
                          : controller.assistedCells.contains(index)
                          ? const Color(0xFF2E7D5B)
                          : colors.primary,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _CandidateMarks extends StatelessWidget {
  const _CandidateMarks({
    required this.mask,
    required this.color,
    required this.patternMask,
    required this.eliminationMask,
  });

  final int mask;
  final Color color;
  final int patternMask;
  final int eliminationMask;

  @override
  Widget build(BuildContext context) {
    if (mask == 0) return const SizedBox.shrink();
    return Column(
      children: [
        for (var candidateRow = 0; candidateRow < 3; candidateRow++)
          Expanded(
            child: Row(
              children: [
                for (
                  var candidateColumn = 0;
                  candidateColumn < 3;
                  candidateColumn++
                )
                  Expanded(
                    child: Center(
                      child: Builder(
                        builder: (_) {
                          final digit = candidateRow * 3 + candidateColumn + 1;
                          final visible =
                              (mask & SudokuEngine.bitFor(digit)) != 0;
                          final highlighted =
                              (patternMask & SudokuEngine.bitFor(digit)) != 0;
                          final eliminated =
                              (eliminationMask & SudokuEngine.bitFor(digit)) !=
                              0;
                          return Text(
                            visible ? '$digit' : '',
                            style: TextStyle(
                              color: eliminated
                                  ? Theme.of(context).colorScheme.error
                                  : highlighted
                                  ? Theme.of(context).colorScheme.tertiary
                                  : color,
                              fontSize: 8.5,
                              height: 1,
                              fontWeight: highlighted || eliminated
                                  ? FontWeight.w800
                                  : FontWeight.normal,
                              decoration: eliminated
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
