import 'package:flutter/material.dart';

import '../controller/game_controller.dart';
import '../logic/logical_solver.dart';
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
            ),
            itemCount: 81,
            itemBuilder: (context, index) =>
                _SudokuCell(index: index, controller: controller),
          ),
          if (controller.hintLinks.isNotEmpty)
            IgnorePointer(
              child: CustomPaint(
                painter: _ChainPainter(
                  links: controller.hintLinks,
                  strongColor: colors.primary,
                  weakColor: colors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChainPainter extends CustomPainter {
  const _ChainPainter({
    required this.links,
    required this.strongColor,
    required this.weakColor,
  });

  final List<LogicalLink> links;
  final Color strongColor;
  final Color weakColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / 9;
    final cellHeight = size.height / 9;
    final nodeRadius = (cellWidth < cellHeight ? cellWidth : cellHeight) / 9;
    final nodeStrengths = <CandidateRef, LogicalLinkStrength>{};

    for (final link in links) {
      final start = _candidateCenter(link.first, cellWidth, cellHeight);
      final end = _candidateCenter(link.second, cellWidth, cellHeight);
      final delta = end - start;
      final distance = delta.distance;
      if (distance == 0) continue;
      final direction = delta / distance;
      final adjustedStart = start + direction * nodeRadius;
      final adjustedEnd = end - direction * nodeRadius;
      final color = link.strength == LogicalLinkStrength.strong
          ? strongColor
          : weakColor;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.92)
        ..strokeWidth = link.strength == LogicalLinkStrength.strong ? 2.2 : 1.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      if (link.strength == LogicalLinkStrength.strong) {
        canvas.drawLine(adjustedStart, adjustedEnd, paint);
      } else {
        _drawDashedLine(canvas, adjustedStart, adjustedEnd, paint);
      }
      for (final candidate in [link.first, link.second]) {
        final previous = nodeStrengths[candidate];
        if (previous == null || link.strength == LogicalLinkStrength.strong) {
          nodeStrengths[candidate] = link.strength;
        }
      }
    }

    for (final entry in nodeStrengths.entries) {
      final color = entry.value == LogicalLinkStrength.strong
          ? strongColor
          : weakColor;
      canvas.drawCircle(
        _candidateCenter(entry.key, cellWidth, cellHeight),
        nodeRadius,
        Paint()
          ..color = color
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke,
      );
    }
  }

  Offset _candidateCenter(
    CandidateRef candidate,
    double cellWidth,
    double cellHeight,
  ) {
    final row = candidate.index ~/ 9;
    final column = candidate.index % 9;
    final candidateRow = (candidate.digit - 1) ~/ 3;
    final candidateColumn = (candidate.digit - 1) % 3;
    return Offset(
      column * cellWidth + (candidateColumn + 0.5) * cellWidth / 3,
      row * cellHeight + (candidateRow + 0.5) * cellHeight / 3,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;
    const dashLength = 5.0;
    const gapLength = 3.5;
    for (
      var offset = 0.0;
      offset < distance;
      offset += dashLength + gapLength
    ) {
      final dashEnd = (offset + dashLength).clamp(0.0, distance);
      canvas.drawLine(
        start + direction * offset,
        start + direction * dashEnd,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ChainPainter oldDelegate) =>
      oldDelegate.links != links ||
      oldDelegate.strongColor != strongColor ||
      oldDelegate.weakColor != weakColor;
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
