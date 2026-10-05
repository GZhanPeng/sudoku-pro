import 'package:flutter/material.dart';

import '../controller/game_controller.dart';
import '../logic/logical_solver.dart';
import '../logic/sudoku_engine.dart';
import '../settings/app_settings.dart';

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
          if (controller.hintLinks.isNotEmpty ||
              controller.hintGroupLinks.isNotEmpty)
            IgnorePointer(
              child: CustomPaint(
                painter: _ChainPainter(
                  links: controller.hintLinks,
                  groupLinks: controller.hintGroupLinks,
                  chainNodes: controller.hintChainNodes,
                  chainGroups: controller.hintChainGroups,
                  isLoop: controller.hintIsLoop,
                  strongColor: colors.primary,
                  weakColor: colors.secondary,
                  endColor: colors.tertiary,
                  nodeSurfaceColor: colors.surface,
                  onStrongColor: colors.onPrimary,
                  onEndColor: colors.onTertiary,
                  onNodeSurfaceColor: colors.onSurface,
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
    required this.groupLinks,
    required this.chainNodes,
    required this.chainGroups,
    required this.isLoop,
    required this.strongColor,
    required this.weakColor,
    required this.endColor,
    required this.nodeSurfaceColor,
    required this.onStrongColor,
    required this.onEndColor,
    required this.onNodeSurfaceColor,
  });

  final List<LogicalLink> links;
  final List<LogicalGroupLink> groupLinks;
  final List<CandidateRef> chainNodes;
  final List<List<CandidateRef>> chainGroups;
  final bool isLoop;
  final Color strongColor;
  final Color weakColor;
  final Color endColor;
  final Color nodeSurfaceColor;
  final Color onStrongColor;
  final Color onEndColor;
  final Color onNodeSurfaceColor;

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

    for (final link in groupLinks) {
      final start = _groupCenter(link.firstGroup, cellWidth, cellHeight);
      final end = _groupCenter(link.secondGroup, cellWidth, cellHeight);
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
        ..strokeWidth = link.strength == LogicalLinkStrength.strong ? 2.6 : 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      if (link.strength == LogicalLinkStrength.strong) {
        canvas.drawLine(adjustedStart, adjustedEnd, paint);
      } else {
        _drawDashedLine(canvas, adjustedStart, adjustedEnd, paint);
      }
      for (final candidate in [...link.firstGroup, ...link.secondGroup]) {
        final previous = nodeStrengths[candidate];
        if (previous == null || link.strength == LogicalLinkStrength.strong) {
          nodeStrengths[candidate] = link.strength;
        }
      }
    }

    for (final entry in nodeStrengths.entries) {
      if (chainNodes.contains(entry.key)) continue;
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

    for (var index = 0; index < chainNodes.length; index++) {
      final candidate = chainNodes[index];
      final isStart = index == 0;
      final isEnd = !isLoop && index == chainNodes.length - 1;
      final fillColor = isStart
          ? strongColor
          : isEnd
          ? endColor
          : nodeSurfaceColor;
      final foregroundColor = isStart
          ? onStrongColor
          : isEnd
          ? onEndColor
          : onNodeSurfaceColor;
      final center = _candidateCenter(candidate, cellWidth, cellHeight);
      final badgeRadius = nodeRadius * 1.35;
      canvas.drawCircle(
        center,
        badgeRadius,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
      if (!isStart && !isEnd) {
        canvas.drawCircle(
          center,
          badgeRadius,
          Paint()
            ..color = strongColor
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke,
        );
      }
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${index + 1}',
          style: TextStyle(
            color: foregroundColor,
            fontSize: badgeRadius * (index >= 9 ? 0.95 : 1.15),
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    for (var index = 0; index < chainGroups.length; index++) {
      final group = chainGroups[index];
      final isStart = index == 0;
      final isEnd = !isLoop && index == chainGroups.length - 1;
      final fillColor = isStart
          ? strongColor
          : isEnd
          ? endColor
          : nodeSurfaceColor;
      final foregroundColor = isStart
          ? onStrongColor
          : isEnd
          ? onEndColor
          : onNodeSurfaceColor;
      final center = _groupCenter(group, cellWidth, cellHeight);
      final badgeRadius = nodeRadius * (group.length > 1 ? 1.65 : 1.35);
      canvas.drawCircle(
        center,
        badgeRadius,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
      if (!isStart && !isEnd) {
        canvas.drawCircle(
          center,
          badgeRadius,
          Paint()
            ..color = strongColor
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke,
        );
      }
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${index + 1}',
          style: TextStyle(
            color: foregroundColor,
            fontSize: badgeRadius * (index >= 9 ? 0.8 : 1.0),
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
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

  Offset _groupCenter(
    List<CandidateRef> group,
    double cellWidth,
    double cellHeight,
  ) {
    var dx = 0.0;
    var dy = 0.0;
    for (final candidate in group) {
      final center = _candidateCenter(candidate, cellWidth, cellHeight);
      dx += center.dx;
      dy += center.dy;
    }
    return Offset(dx / group.length, dy / group.length);
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
      oldDelegate.groupLinks != groupLinks ||
      oldDelegate.chainNodes != chainNodes ||
      oldDelegate.chainGroups != chainGroups ||
      oldDelegate.isLoop != isLoop ||
      oldDelegate.strongColor != strongColor ||
      oldDelegate.weakColor != weakColor ||
      oldDelegate.endColor != endColor ||
      oldDelegate.nodeSurfaceColor != nodeSurfaceColor ||
      oldDelegate.onStrongColor != onStrongColor ||
      oldDelegate.onEndColor != onEndColor ||
      oldDelegate.onNodeSurfaceColor != onNodeSurfaceColor;
}

class _SudokuCell extends StatelessWidget {
  const _SudokuCell({required this.index, required this.controller});

  final int index;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final preferences = AppSettingsScope.preferencesOf(context);
    final row = index ~/ 9;
    final column = index % 9;
    final selected = controller.selectedIndex == index;
    final sameValue = controller.hasSameValueAsSelected(index);
    final peer = controller.isPeerOfSelected(index);
    final value = controller.valueAt(index);
    final conflicting = controller.isConflictingCell(index);
    final candidateMask = controller.visibleCandidateMaskAt(index);
    final focusDigit = controller.highlightedDigit;
    final focusMask =
        preferences.highlightSameDigit &&
            preferences.candidateHighlightMode != CandidateHighlightMode.off &&
            focusDigit != null
        ? SudokuEngine.bitFor(focusDigit)
        : 0;
    final sameCandidate = (candidateMask & focusMask) != 0;

    Color background = colors.surface;
    if (peer && preferences.highlightPeers) {
      background = colors.onSurface.withValues(alpha: 0.045);
    }
    if ((sameValue && preferences.highlightSameDigit) ||
        (sameCandidate &&
            preferences.candidateHighlightMode ==
                CandidateHighlightMode.digitAndCell)) {
      background = colors.secondaryContainer;
    }
    if (controller.isHintPatternCell(index)) {
      background = colors.tertiaryContainer;
    }
    if (controller.isHintAffectedCell(index)) {
      background = colors.errorContainer.withValues(alpha: 0.72);
    }
    if (selected) background = colors.primaryContainer;

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
                  mask: candidateMask,
                  focusMask: focusMask,
                  conflictingMask: preferences.warnCandidateConflicts
                      ? controller.manualCandidateMasks[index] &
                            ~controller.legalMaskAt(index)
                      : 0,
                  fontSize: preferences.candidateSize.fontSize,
                  color: colors.onSurfaceVariant,
                  patternMask: controller.hintPatternMaskAt(index),
                  eliminationMask: controller.hintEliminationMaskAt(index),
                  colorAMask: controller.hintCandidateColorMaskAt(index, 0),
                  colorBMask: controller.hintCandidateColorMaskAt(index, 1),
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
    required this.focusMask,
    required this.conflictingMask,
    required this.fontSize,
    required this.color,
    required this.patternMask,
    required this.eliminationMask,
    required this.colorAMask,
    required this.colorBMask,
  });

  final int mask;
  final int focusMask;
  final int conflictingMask;
  final double fontSize;
  final Color color;
  final int patternMask;
  final int eliminationMask;
  final int colorAMask;
  final int colorBMask;

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
                          final focused =
                              visible &&
                              (focusMask & SudokuEngine.bitFor(digit)) != 0;
                          final conflicting =
                              (conflictingMask & SudokuEngine.bitFor(digit)) !=
                              0;
                          final highlighted =
                              (patternMask & SudokuEngine.bitFor(digit)) != 0;
                          final eliminated =
                              (eliminationMask & SudokuEngine.bitFor(digit)) !=
                              0;
                          final colorA =
                              (colorAMask & SudokuEngine.bitFor(digit)) != 0;
                          final colorB =
                              (colorBMask & SudokuEngine.bitFor(digit)) != 0;
                          final brightness = Theme.of(context).brightness;
                          final candidateColor = colorA
                              ? brightness == Brightness.light
                                    ? const Color(0xFF1565C0)
                                    : const Color(0xFF64B5F6)
                              : colorB
                              ? brightness == Brightness.light
                                    ? const Color(0xFFEF6C00)
                                    : const Color(0xFFFFB74D)
                              : null;
                          final colors = Theme.of(context).colorScheme;
                          return Container(
                            padding: candidateColor == null && !focused
                                ? EdgeInsets.zero
                                : const EdgeInsets.all(1.2),
                            decoration: candidateColor == null && !focused
                                ? null
                                : BoxDecoration(
                                    color: candidateColor != null
                                        ? candidateColor.withValues(alpha: 0.16)
                                        : colors.secondaryContainer,
                                    border: focused
                                        ? Border.all(
                                            color:
                                                candidateColor ??
                                                colors.secondary,
                                            width: 0.8,
                                          )
                                        : null,
                                    shape: BoxShape.circle,
                                  ),
                            child: Text(
                              visible ? '$digit' : '',
                              style: TextStyle(
                                color: conflicting || eliminated
                                    ? Theme.of(context).colorScheme.error
                                    : candidateColor ??
                                          (highlighted
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                              : focused
                                              ? colors.onSecondaryContainer
                                              : color),
                                fontSize: fontSize,
                                height: 1,
                                fontWeight:
                                    focused ||
                                        highlighted ||
                                        conflicting ||
                                        eliminated ||
                                        candidateColor != null
                                    ? FontWeight.w800
                                    : FontWeight.normal,
                                decoration: eliminated
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
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
