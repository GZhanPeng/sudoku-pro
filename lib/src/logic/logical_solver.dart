import '../model/sudoku_board.dart';
import 'sudoku_engine.dart';

enum PuzzleDifficulty { beginner, easy, medium, hard }

extension PuzzleDifficultyInfo on PuzzleDifficulty {
  String get label => switch (this) {
    PuzzleDifficulty.beginner => '入门',
    PuzzleDifficulty.easy => '简单',
    PuzzleDifficulty.medium => '中等',
    PuzzleDifficulty.hard => '困难',
  };

  String get description => switch (this) {
    PuzzleDifficulty.beginner => '唯余与宫行列摈除',
    PuzzleDifficulty.easy => '加入区块摈除和显性数对',
    PuzzleDifficulty.medium => '加入数组、隐性数对和 X-Wing',
    PuzzleDifficulty.hard => '加入翼、短链和分组结构',
  };

  int get rank => index;
}

enum LogicalTechnique {
  nakedSingle,
  hiddenSingle,
  lockedPointing,
  lockedClaiming,
  nakedPair,
  nakedTriple,
  hiddenPair,
  hiddenTriple,
  xWing,
  skyscraper,
  twoStringKite,
  emptyRectangle,
  wWing,
  xyWing,
}

extension LogicalTechniqueInfo on LogicalTechnique {
  String get label => switch (this) {
    LogicalTechnique.nakedSingle => '唯余',
    LogicalTechnique.hiddenSingle => '宫行列摈除',
    LogicalTechnique.lockedPointing => '宫区块摈除',
    LogicalTechnique.lockedClaiming => '行列区块摈除',
    LogicalTechnique.nakedPair => '显性数对',
    LogicalTechnique.nakedTriple => '显性三数组',
    LogicalTechnique.hiddenPair => '隐性数对',
    LogicalTechnique.hiddenTriple => '隐性三数组',
    LogicalTechnique.xWing => 'X-Wing',
    LogicalTechnique.skyscraper => '摩天楼',
    LogicalTechnique.twoStringKite => '双线风筝',
    LogicalTechnique.emptyRectangle => '空矩形',
    LogicalTechnique.wWing => 'W-Wing',
    LogicalTechnique.xyWing => 'XY-Wing',
  };

  PuzzleDifficulty get difficulty => switch (this) {
    LogicalTechnique.nakedSingle ||
    LogicalTechnique.hiddenSingle => PuzzleDifficulty.beginner,
    LogicalTechnique.lockedPointing ||
    LogicalTechnique.lockedClaiming ||
    LogicalTechnique.nakedPair => PuzzleDifficulty.easy,
    LogicalTechnique.nakedTriple ||
    LogicalTechnique.hiddenPair ||
    LogicalTechnique.hiddenTriple ||
    LogicalTechnique.xWing => PuzzleDifficulty.medium,
    LogicalTechnique.skyscraper ||
    LogicalTechnique.twoStringKite ||
    LogicalTechnique.emptyRectangle ||
    LogicalTechnique.wWing ||
    LogicalTechnique.xyWing => PuzzleDifficulty.hard,
  };
}

class CandidateRef {
  const CandidateRef(this.index, this.digit);

  final int index;
  final int digit;

  @override
  bool operator ==(Object other) =>
      other is CandidateRef && other.index == index && other.digit == digit;

  @override
  int get hashCode => Object.hash(index, digit);
}

enum LogicalLinkStrength { strong, weak }

class LogicalLink {
  const LogicalLink({
    required this.first,
    required this.second,
    required this.strength,
  });

  final CandidateRef first;
  final CandidateRef second;
  final LogicalLinkStrength strength;

  @override
  bool operator ==(Object other) =>
      other is LogicalLink &&
      other.first == first &&
      other.second == second &&
      other.strength == strength;

  @override
  int get hashCode => Object.hash(first, second, strength);
}

class LogicalGroupLink {
  const LogicalGroupLink({
    required this.firstGroup,
    required this.secondGroup,
    required this.strength,
  });

  final List<CandidateRef> firstGroup;
  final List<CandidateRef> secondGroup;
  final LogicalLinkStrength strength;
}

class LogicalStep {
  const LogicalStep({
    required this.technique,
    required this.pattern,
    required this.eliminations,
    required this.focus,
    required this.explanation,
    this.placementIndex,
    this.placementDigit,
    this.links = const [],
    this.groupLinks = const [],
  });

  final LogicalTechnique technique;
  final List<CandidateRef> pattern;
  final List<CandidateRef> eliminations;
  final int? placementIndex;
  final int? placementDigit;
  final List<LogicalLink> links;
  final List<LogicalGroupLink> groupLinks;
  final String focus;
  final String explanation;

  bool get isPlacement => placementIndex != null;
  PuzzleDifficulty get difficulty => technique.difficulty;

  Set<int> get patternCells => pattern.map((item) => item.index).toSet();
  Set<int> get affectedCells {
    final cells = eliminations.map((item) => item.index).toSet();
    final placement = placementIndex;
    if (placement != null) cells.add(placement);
    return cells;
  }

  int patternMaskAt(int index) {
    var mask = 0;
    for (final item in pattern) {
      if (item.index == index) mask |= SudokuEngine.bitFor(item.digit);
    }
    return mask;
  }

  int eliminationMaskAt(int index) {
    var mask = 0;
    for (final item in eliminations) {
      if (item.index == index) mask |= SudokuEngine.bitFor(item.digit);
    }
    return mask;
  }
}

class LogicalSolveResult {
  const LogicalSolveResult({
    required this.values,
    required this.excludedMasks,
    required this.steps,
    required this.solved,
    required this.hardestDifficulty,
    this.error,
  });

  final List<int> values;
  final List<int> excludedMasks;
  final List<LogicalStep> steps;
  final bool solved;
  final PuzzleDifficulty hardestDifficulty;
  final String? error;
}

class LogicalSolver {
  const LogicalSolver({this.engine = const SudokuEngine()});

  final SudokuEngine engine;

  LogicalStep? findNext({
    required List<int> values,
    required List<int> excludedMasks,
    PuzzleDifficulty maxDifficulty = PuzzleDifficulty.hard,
  }) {
    if (values.length != SudokuBoard.cellCount ||
        excludedMasks.length != SudokuBoard.cellCount ||
        engine.validate(values) != null) {
      return null;
    }
    final masks = _candidateMasks(values, excludedMasks);
    if (_hasEmptyCellWithoutCandidate(values, masks)) return null;

    LogicalStep? step;
    step = _findNakedSingle(values, masks);
    if (step != null) return step;
    step = _findHiddenSingle(values, masks);
    if (step != null) return step;

    if (maxDifficulty.rank >= PuzzleDifficulty.easy.rank) {
      step = _findLockedPointing(values, masks);
      if (step != null) return step;
      step = _findLockedClaiming(values, masks);
      if (step != null) return step;
      step = _findNakedSubset(values, masks, 2);
      if (step != null) return step;
    }

    if (maxDifficulty.rank >= PuzzleDifficulty.medium.rank) {
      step = _findHiddenSubset(values, masks, 2);
      if (step != null) return step;
      step = _findNakedSubset(values, masks, 3);
      if (step != null) return step;
      step = _findHiddenSubset(values, masks, 3);
      if (step != null) return step;
      step = _findXWing(values, masks);
      if (step != null) return step;
    }

    if (maxDifficulty.rank >= PuzzleDifficulty.hard.rank) {
      step = _findSkyscraper(masks);
      if (step != null) return step;
      step = _findTwoStringKite(masks);
      if (step != null) return step;
      step = _findEmptyRectangle(masks);
      if (step != null) return step;
      step = _findWWing(masks);
      if (step != null) return step;
      step = _findXYWing(values, masks);
      if (step != null) return step;
    }
    return null;
  }

  LogicalStep? findTechnique({
    required List<int> values,
    required List<int> excludedMasks,
    required LogicalTechnique technique,
  }) {
    if (values.length != SudokuBoard.cellCount ||
        excludedMasks.length != SudokuBoard.cellCount ||
        engine.validate(values) != null) {
      return null;
    }
    final masks = _candidateMasks(values, excludedMasks);
    if (_hasEmptyCellWithoutCandidate(values, masks)) return null;
    return switch (technique) {
      LogicalTechnique.nakedSingle => _findNakedSingle(values, masks),
      LogicalTechnique.hiddenSingle => _findHiddenSingle(values, masks),
      LogicalTechnique.lockedPointing => _findLockedPointing(values, masks),
      LogicalTechnique.lockedClaiming => _findLockedClaiming(values, masks),
      LogicalTechnique.nakedPair => _findNakedSubset(values, masks, 2),
      LogicalTechnique.nakedTriple => _findNakedSubset(values, masks, 3),
      LogicalTechnique.hiddenPair => _findHiddenSubset(values, masks, 2),
      LogicalTechnique.hiddenTriple => _findHiddenSubset(values, masks, 3),
      LogicalTechnique.xWing => _findXWing(values, masks),
      LogicalTechnique.skyscraper => _findSkyscraper(masks),
      LogicalTechnique.twoStringKite => _findTwoStringKite(masks),
      LogicalTechnique.emptyRectangle => _findEmptyRectangle(masks),
      LogicalTechnique.wWing => _findWWing(masks),
      LogicalTechnique.xyWing => _findXYWing(values, masks),
    };
  }

  LogicalSolveResult solve(
    List<int> source, {
    PuzzleDifficulty maxDifficulty = PuzzleDifficulty.hard,
    int maxSteps = 600,
  }) {
    final values = List<int>.of(source);
    final excludedMasks = List<int>.filled(SudokuBoard.cellCount, 0);
    final steps = <LogicalStep>[];
    var hardest = PuzzleDifficulty.beginner;
    final validationError = engine.validate(values);
    if (validationError != null) {
      return LogicalSolveResult(
        values: values,
        excludedMasks: excludedMasks,
        steps: steps,
        solved: false,
        hardestDifficulty: hardest,
        error: validationError,
      );
    }

    while (values.any((value) => value == 0) && steps.length < maxSteps) {
      final step = findNext(
        values: values,
        excludedMasks: excludedMasks,
        maxDifficulty: maxDifficulty,
      );
      if (step == null) break;
      applyStep(values: values, excludedMasks: excludedMasks, step: step);
      steps.add(step);
      if (step.difficulty.rank > hardest.rank) hardest = step.difficulty;
    }

    return LogicalSolveResult(
      values: values,
      excludedMasks: excludedMasks,
      steps: steps,
      solved: values.every((value) => value != 0),
      hardestDifficulty: hardest,
      error: steps.length >= maxSteps ? '逻辑求解步数超过上限' : null,
    );
  }

  void applyStep({
    required List<int> values,
    required List<int> excludedMasks,
    required LogicalStep step,
  }) {
    if (step.placementIndex case final index?) {
      values[index] = step.placementDigit!;
      excludedMasks[index] = 0;
      return;
    }
    for (final elimination in step.eliminations) {
      excludedMasks[elimination.index] |= SudokuEngine.bitFor(
        elimination.digit,
      );
    }
  }

  List<int> _candidateMasks(List<int> values, List<int> excludedMasks) =>
      List<int>.generate(
        SudokuBoard.cellCount,
        (index) => values[index] == 0
            ? engine.legalMask(values, index) & ~excludedMasks[index]
            : 0,
        growable: false,
      );

  bool _hasEmptyCellWithoutCandidate(List<int> values, List<int> masks) {
    for (var index = 0; index < SudokuBoard.cellCount; index++) {
      if (values[index] == 0 && masks[index] == 0) return true;
    }
    return false;
  }

  LogicalStep? _findNakedSingle(List<int> values, List<int> masks) {
    for (var index = 0; index < SudokuBoard.cellCount; index++) {
      if (values[index] != 0 || SudokuEngine.countBits(masks[index]) != 1) {
        continue;
      }
      final digit = SudokuEngine.singleDigit(masks[index]);
      return LogicalStep(
        technique: LogicalTechnique.nakedSingle,
        pattern: [CandidateRef(index, digit)],
        eliminations: const [],
        placementIndex: index,
        placementDigit: digit,
        focus: '观察 ${_cellLabel(index)} 的候选数。',
        explanation: '${_cellLabel(index)} 只剩候选 $digit，因此这一格必须填 $digit。',
      );
    }
    return null;
  }

  LogicalStep? _findHiddenSingle(List<int> values, List<int> masks) {
    for (final unit in _units) {
      var placedMask = 0;
      for (final index in unit.cells) {
        final value = values[index];
        if (value != 0) placedMask |= SudokuEngine.bitFor(value);
      }
      for (var digit = 1; digit <= 9; digit++) {
        final bit = SudokuEngine.bitFor(digit);
        if ((placedMask & bit) != 0) continue;
        final possible = [
          for (final index in unit.cells)
            if (values[index] == 0 && (masks[index] & bit) != 0) index,
        ];
        if (possible.length != 1) continue;
        final index = possible.single;
        return LogicalStep(
          technique: LogicalTechnique.hiddenSingle,
          pattern: [CandidateRef(index, digit)],
          eliminations: const [],
          placementIndex: index,
          placementDigit: digit,
          focus: '观察${unit.label}中数字 $digit 能出现的位置。',
          explanation:
              '${unit.label}中只有 ${_cellLabel(index)} 可以放入 $digit，因此该格必须填 $digit。',
        );
      }
    }
    return null;
  }

  LogicalStep? _findLockedPointing(List<int> values, List<int> masks) {
    for (var box = 0; box < 9; box++) {
      final cells = SudokuEngine.boxes[box];
      for (var digit = 1; digit <= 9; digit++) {
        final bit = SudokuEngine.bitFor(digit);
        final positions = [
          for (final index in cells)
            if (values[index] == 0 && (masks[index] & bit) != 0) index,
        ];
        if (positions.length < 2) continue;
        final rows = positions.map((index) => index ~/ 9).toSet();
        final columns = positions.map((index) => index % 9).toSet();
        List<CandidateRef> eliminations = const [];
        String? lineLabel;
        if (rows.length == 1) {
          final row = rows.single;
          eliminations = [
            for (final index in SudokuEngine.rows[row])
              if (!cells.contains(index) && (masks[index] & bit) != 0)
                CandidateRef(index, digit),
          ];
          lineLabel = '第 ${row + 1} 行';
        } else if (columns.length == 1) {
          final column = columns.single;
          eliminations = [
            for (final index in SudokuEngine.columns[column])
              if (!cells.contains(index) && (masks[index] & bit) != 0)
                CandidateRef(index, digit),
          ];
          lineLabel = '第 ${column + 1} 列';
        }
        if (eliminations.isEmpty || lineLabel == null) continue;
        return LogicalStep(
          technique: LogicalTechnique.lockedPointing,
          pattern: [for (final index in positions) CandidateRef(index, digit)],
          eliminations: eliminations,
          focus: '观察第 ${box + 1} 宫中候选 $digit 的分布。',
          explanation:
              '第 ${box + 1} 宫的 $digit 全部锁定在$lineLabel，所以可以从该${lineLabel.endsWith('行') ? '行' : '列'}的其他宫中删除候选 $digit。',
        );
      }
    }
    return null;
  }

  LogicalStep? _findLockedClaiming(List<int> values, List<int> masks) {
    for (var typeIndex = 0; typeIndex < 2; typeIndex++) {
      final lines = typeIndex == 0 ? SudokuEngine.rows : SudokuEngine.columns;
      for (var line = 0; line < 9; line++) {
        final cells = lines[line];
        for (var digit = 1; digit <= 9; digit++) {
          final bit = SudokuEngine.bitFor(digit);
          final positions = [
            for (final index in cells)
              if (values[index] == 0 && (masks[index] & bit) != 0) index,
          ];
          if (positions.length < 2) continue;
          final boxes = positions.map(_boxOf).toSet();
          if (boxes.length != 1) continue;
          final box = boxes.single;
          final eliminations = [
            for (final index in SudokuEngine.boxes[box])
              if (!cells.contains(index) && (masks[index] & bit) != 0)
                CandidateRef(index, digit),
          ];
          if (eliminations.isEmpty) continue;
          final lineLabel = typeIndex == 0
              ? '第 ${line + 1} 行'
              : '第 ${line + 1} 列';
          return LogicalStep(
            technique: LogicalTechnique.lockedClaiming,
            pattern: [
              for (final index in positions) CandidateRef(index, digit),
            ],
            eliminations: eliminations,
            focus: '观察$lineLabel中候选 $digit 所在的宫。',
            explanation:
                '$lineLabel中的 $digit 都在第 ${box + 1} 宫，所以可以从该宫的其他格删除候选 $digit。',
          );
        }
      }
    }
    return null;
  }

  LogicalStep? _findNakedSubset(List<int> values, List<int> masks, int size) {
    for (final unit in _units) {
      final candidates = [
        for (final index in unit.cells)
          if (values[index] == 0 &&
              SudokuEngine.countBits(masks[index]) >= 2 &&
              SudokuEngine.countBits(masks[index]) <= size)
            index,
      ];
      for (final selected in _combinations(candidates, size)) {
        var unionMask = 0;
        for (final index in selected) {
          unionMask |= masks[index];
        }
        if (SudokuEngine.countBits(unionMask) != size) continue;
        final eliminations = <CandidateRef>[];
        for (final index in unit.cells) {
          if (selected.contains(index) || values[index] != 0) continue;
          final removable = masks[index] & unionMask;
          for (final digit in SudokuEngine.digitsInMask(removable)) {
            eliminations.add(CandidateRef(index, digit));
          }
        }
        if (eliminations.isEmpty) continue;
        final digits = SudokuEngine.digitsInMask(unionMask);
        return LogicalStep(
          technique: size == 2
              ? LogicalTechnique.nakedPair
              : LogicalTechnique.nakedTriple,
          pattern: [
            for (final index in selected)
              for (final digit in SudokuEngine.digitsInMask(masks[index]))
                CandidateRef(index, digit),
          ],
          eliminations: eliminations,
          focus: '观察${unit.label}中 ${selected.map(_cellLabel).join('、')} 的候选数。',
          explanation:
              '这 ${size == 2 ? '两' : '三'} 格只占用 ${digits.join('、')} 这 $size 个数，所以${unit.label}其他格可以删除这些候选。',
        );
      }
    }
    return null;
  }

  LogicalStep? _findHiddenSubset(List<int> values, List<int> masks, int size) {
    for (final unit in _units) {
      final availableDigits = <int>[];
      for (var digit = 1; digit <= 9; digit++) {
        final bit = SudokuEngine.bitFor(digit);
        if (unit.cells.any((index) => (masks[index] & bit) != 0)) {
          availableDigits.add(digit);
        }
      }
      for (final digits in _combinations(availableDigits, size)) {
        final positions = <int>{};
        var digitMask = 0;
        var everyDigitAppears = true;
        for (final digit in digits) {
          final bit = SudokuEngine.bitFor(digit);
          digitMask |= bit;
          final digitPositions = [
            for (final index in unit.cells)
              if ((masks[index] & bit) != 0) index,
          ];
          if (digitPositions.isEmpty) {
            everyDigitAppears = false;
            break;
          }
          positions.addAll(digitPositions);
        }
        if (!everyDigitAppears || positions.length != size) continue;
        final eliminations = <CandidateRef>[];
        for (final index in positions) {
          final removable = masks[index] & ~digitMask;
          for (final digit in SudokuEngine.digitsInMask(removable)) {
            eliminations.add(CandidateRef(index, digit));
          }
        }
        if (eliminations.isEmpty) continue;
        return LogicalStep(
          technique: size == 2
              ? LogicalTechnique.hiddenPair
              : LogicalTechnique.hiddenTriple,
          pattern: [
            for (final index in positions)
              for (final digit in digits)
                if ((masks[index] & SudokuEngine.bitFor(digit)) != 0)
                  CandidateRef(index, digit),
          ],
          eliminations: eliminations,
          focus: '观察${unit.label}中数字 ${digits.join('、')} 能出现的位置。',
          explanation:
              '${digits.join('、')} 只能出现在 ${positions.map(_cellLabel).join('、')}，这些格的其他候选都可删除。',
        );
      }
    }
    return null;
  }

  LogicalStep? _findXWing(List<int> values, List<int> masks) {
    for (var digit = 1; digit <= 9; digit++) {
      final bit = SudokuEngine.bitFor(digit);
      final rowPositions = <int, List<int>>{};
      for (var row = 0; row < 9; row++) {
        final columns = [
          for (var column = 0; column < 9; column++)
            if ((masks[row * 9 + column] & bit) != 0) column,
        ];
        if (columns.length == 2) rowPositions[row] = columns;
      }
      final rowKeys = rowPositions.keys.toList();
      for (final rows in _combinations(rowKeys, 2)) {
        final first = rowPositions[rows[0]]!;
        final second = rowPositions[rows[1]]!;
        if (first[0] != second[0] || first[1] != second[1]) continue;
        final eliminations = <CandidateRef>[];
        for (var row = 0; row < 9; row++) {
          if (rows.contains(row)) continue;
          for (final column in first) {
            final index = row * 9 + column;
            if ((masks[index] & bit) != 0) {
              eliminations.add(CandidateRef(index, digit));
            }
          }
        }
        if (eliminations.isEmpty) continue;
        final patternIndices = [
          for (final row in rows)
            for (final column in first) row * 9 + column,
        ];
        return LogicalStep(
          technique: LogicalTechnique.xWing,
          pattern: [
            for (final index in patternIndices) CandidateRef(index, digit),
          ],
          eliminations: eliminations,
          focus: '观察第 ${rows[0] + 1}、${rows[1] + 1} 行中候选 $digit 的列位置。',
          explanation:
              '两行的 $digit 都只在第 ${first[0] + 1}、${first[1] + 1} 列，形成 X-Wing，因此这两列的其他格可删除 $digit。',
        );
      }

      final columnPositions = <int, List<int>>{};
      for (var column = 0; column < 9; column++) {
        final rows = [
          for (var row = 0; row < 9; row++)
            if ((masks[row * 9 + column] & bit) != 0) row,
        ];
        if (rows.length == 2) columnPositions[column] = rows;
      }
      final columnKeys = columnPositions.keys.toList();
      for (final columns in _combinations(columnKeys, 2)) {
        final first = columnPositions[columns[0]]!;
        final second = columnPositions[columns[1]]!;
        if (first[0] != second[0] || first[1] != second[1]) continue;
        final eliminations = <CandidateRef>[];
        for (var column = 0; column < 9; column++) {
          if (columns.contains(column)) continue;
          for (final row in first) {
            final index = row * 9 + column;
            if ((masks[index] & bit) != 0) {
              eliminations.add(CandidateRef(index, digit));
            }
          }
        }
        if (eliminations.isEmpty) continue;
        final patternIndices = [
          for (final column in columns)
            for (final row in first) row * 9 + column,
        ];
        return LogicalStep(
          technique: LogicalTechnique.xWing,
          pattern: [
            for (final index in patternIndices) CandidateRef(index, digit),
          ],
          eliminations: eliminations,
          focus: '观察第 ${columns[0] + 1}、${columns[1] + 1} 列中候选 $digit 的行位置。',
          explanation:
              '两列的 $digit 都只在第 ${first[0] + 1}、${first[1] + 1} 行，形成 X-Wing，因此这两行的其他格可删除 $digit。',
        );
      }
    }
    return null;
  }

  LogicalStep? _findSkyscraper(List<int> masks) {
    for (var digit = 1; digit <= 9; digit++) {
      final bit = SudokuEngine.bitFor(digit);
      for (var rowBased = 0; rowBased < 2; rowBased++) {
        final lines = rowBased == 0 ? SudokuEngine.rows : SudokuEngine.columns;
        final conjugateLines = <int, List<int>>{};
        for (var line = 0; line < 9; line++) {
          final positions = [
            for (final index in lines[line])
              if ((masks[index] & bit) != 0) index,
          ];
          if (positions.length == 2) conjugateLines[line] = positions;
        }

        final lineNumbers = conjugateLines.keys.toList();
        for (final pair in _combinations(lineNumbers, 2)) {
          final firstPair = conjugateLines[pair[0]]!;
          final secondPair = conjugateLines[pair[1]]!;
          final commonCrossCoordinates = firstPair
              .map((index) => rowBased == 0 ? index % 9 : index ~/ 9)
              .toSet()
              .intersection(
                secondPair
                    .map((index) => rowBased == 0 ? index % 9 : index ~/ 9)
                    .toSet(),
              );
          if (commonCrossCoordinates.length != 1) continue;

          final baseCoordinate = commonCrossCoordinates.single;
          final firstBase = firstPair.singleWhere(
            (index) =>
                (rowBased == 0 ? index % 9 : index ~/ 9) == baseCoordinate,
          );
          final secondBase = secondPair.singleWhere(
            (index) =>
                (rowBased == 0 ? index % 9 : index ~/ 9) == baseCoordinate,
          );
          final firstRoof = firstPair.firstWhere((index) => index != firstBase);
          final secondRoof = secondPair.firstWhere(
            (index) => index != secondBase,
          );
          final patternIndices = {firstRoof, firstBase, secondBase, secondRoof};
          final eliminations = _commonPeerEliminations(
            masks: masks,
            digit: digit,
            first: firstRoof,
            second: secondRoof,
            excludedIndices: patternIndices,
          );
          if (eliminations.isEmpty) continue;

          final lineName = rowBased == 0 ? '行' : '列';
          final baseName = rowBased == 0 ? '列' : '行';
          return LogicalStep(
            technique: LogicalTechnique.skyscraper,
            pattern: [
              for (final index in patternIndices) CandidateRef(index, digit),
            ],
            eliminations: eliminations,
            links: [
              LogicalLink(
                first: CandidateRef(firstRoof, digit),
                second: CandidateRef(firstBase, digit),
                strength: LogicalLinkStrength.strong,
              ),
              LogicalLink(
                first: CandidateRef(firstBase, digit),
                second: CandidateRef(secondBase, digit),
                strength: LogicalLinkStrength.weak,
              ),
              LogicalLink(
                first: CandidateRef(secondBase, digit),
                second: CandidateRef(secondRoof, digit),
                strength: LogicalLinkStrength.strong,
              ),
            ],
            focus:
                '观察第 ${pair[0] + 1}、${pair[1] + 1} $lineName中候选 $digit 的两组强链。',
            explanation:
                '两条$lineName的候选 $digit 各只剩两处，其中一端对齐在第 ${baseCoordinate + 1} $baseName，形成“强—弱—强”的摩天楼链。两个楼顶至少有一个为真，所以同时看到两个楼顶的格可删除 $digit。',
          );
        }
      }
    }
    return null;
  }

  LogicalStep? _findTwoStringKite(List<int> masks) {
    for (var digit = 1; digit <= 9; digit++) {
      final bit = SudokuEngine.bitFor(digit);
      final rowPairs = <int, List<int>>{};
      final columnPairs = <int, List<int>>{};
      for (var row = 0; row < 9; row++) {
        final positions = [
          for (final index in SudokuEngine.rows[row])
            if ((masks[index] & bit) != 0) index,
        ];
        if (positions.length == 2) rowPairs[row] = positions;
      }
      for (var column = 0; column < 9; column++) {
        final positions = [
          for (final index in SudokuEngine.columns[column])
            if ((masks[index] & bit) != 0) index,
        ];
        if (positions.length == 2) columnPairs[column] = positions;
      }

      for (final rowEntry in rowPairs.entries) {
        for (final columnEntry in columnPairs.entries) {
          for (final rowJoint in rowEntry.value) {
            final rowTip = rowEntry.value.firstWhere(
              (index) => index != rowJoint,
            );
            for (final columnJoint in columnEntry.value) {
              final columnTip = columnEntry.value.firstWhere(
                (index) => index != columnJoint,
              );
              final patternIndices = {rowTip, rowJoint, columnJoint, columnTip};
              if (patternIndices.length != 4 ||
                  _boxOf(rowJoint) != _boxOf(columnJoint)) {
                continue;
              }
              final eliminations = _commonPeerEliminations(
                masks: masks,
                digit: digit,
                first: rowTip,
                second: columnTip,
                excludedIndices: patternIndices,
              );
              if (eliminations.isEmpty) continue;

              return LogicalStep(
                technique: LogicalTechnique.twoStringKite,
                pattern: [
                  for (final index in patternIndices)
                    CandidateRef(index, digit),
                ],
                eliminations: eliminations,
                links: [
                  LogicalLink(
                    first: CandidateRef(rowTip, digit),
                    second: CandidateRef(rowJoint, digit),
                    strength: LogicalLinkStrength.strong,
                  ),
                  LogicalLink(
                    first: CandidateRef(rowJoint, digit),
                    second: CandidateRef(columnJoint, digit),
                    strength: LogicalLinkStrength.weak,
                  ),
                  LogicalLink(
                    first: CandidateRef(columnJoint, digit),
                    second: CandidateRef(columnTip, digit),
                    strength: LogicalLinkStrength.strong,
                  ),
                ],
                focus:
                    '观察第 ${rowEntry.key + 1} 行和第 ${columnEntry.key + 1} 列中候选 $digit 的强链。',
                explanation:
                    '第 ${rowEntry.key + 1} 行与第 ${columnEntry.key + 1} 列的 $digit 都各只剩两处，两条强链在第 ${_boxOf(rowJoint) + 1} 宫内以弱链衔接，形成双线风筝。两个风筝尖端至少有一个为真，因此同时看到两个尖端的格可删除 $digit。',
              );
            }
          }
        }
      }
    }
    return null;
  }

  List<CandidateRef> _commonPeerEliminations({
    required List<int> masks,
    required int digit,
    required int first,
    required int second,
    required Set<int> excludedIndices,
  }) {
    final bit = SudokuEngine.bitFor(digit);
    return [
      for (var index = 0; index < SudokuBoard.cellCount; index++)
        if (!excludedIndices.contains(index) &&
            (masks[index] & bit) != 0 &&
            _arePeers(index, first) &&
            _arePeers(index, second))
          CandidateRef(index, digit),
    ];
  }

  LogicalStep? _findEmptyRectangle(List<int> masks) {
    for (var digit = 1; digit <= 9; digit++) {
      final bit = SudokuEngine.bitFor(digit);
      for (var box = 0; box < 9; box++) {
        final boxCandidates = [
          for (final index in SudokuEngine.boxes[box])
            if ((masks[index] & bit) != 0) index,
        ];
        if (boxCandidates.length < 3) continue;
        final boxRows = SudokuEngine.boxes[box]
            .map((index) => index ~/ 9)
            .toSet();
        final boxColumns = SudokuEngine.boxes[box]
            .map((index) => index % 9)
            .toSet();

        for (final erRow in boxRows) {
          for (final erColumn in boxColumns) {
            final intersection = erRow * 9 + erColumn;
            if ((masks[intersection] & bit) != 0 ||
                !boxCandidates.every(
                  (index) => index ~/ 9 == erRow || index % 9 == erColumn,
                )) {
              continue;
            }
            final rowArm = [
              for (final index in boxCandidates)
                if (index ~/ 9 == erRow) CandidateRef(index, digit),
            ];
            final columnArm = [
              for (final index in boxCandidates)
                if (index % 9 == erColumn) CandidateRef(index, digit),
            ];
            if (rowArm.isEmpty || columnArm.isEmpty) continue;

            for (var linkColumn = 0; linkColumn < 9; linkColumn++) {
              if (boxColumns.contains(linkColumn)) continue;
              final near = erRow * 9 + linkColumn;
              final conjugate = [
                for (final index in SudokuEngine.columns[linkColumn])
                  if ((masks[index] & bit) != 0) index,
              ];
              if (conjugate.length != 2 || !conjugate.contains(near)) {
                continue;
              }
              final far = conjugate.firstWhere((index) => index != near);
              final target = far ~/ 9 * 9 + erColumn;
              if (_boxOf(target) == box || (masks[target] & bit) == 0) {
                continue;
              }
              return _emptyRectangleStep(
                digit: digit,
                box: box,
                rowArm: rowArm,
                columnArm: columnArm,
                near: near,
                far: far,
                target: target,
                externalUnit:
                    '第 ${linkColumn + 1} 列 ${_cellLabel(near)}—${_cellLabel(far)}',
                connectedArm: rowArm,
                oppositeArm: columnArm,
              );
            }

            for (var linkRow = 0; linkRow < 9; linkRow++) {
              if (boxRows.contains(linkRow)) continue;
              final near = linkRow * 9 + erColumn;
              final conjugate = [
                for (final index in SudokuEngine.rows[linkRow])
                  if ((masks[index] & bit) != 0) index,
              ];
              if (conjugate.length != 2 || !conjugate.contains(near)) {
                continue;
              }
              final far = conjugate.firstWhere((index) => index != near);
              final target = erRow * 9 + far % 9;
              if (_boxOf(target) == box || (masks[target] & bit) == 0) {
                continue;
              }
              return _emptyRectangleStep(
                digit: digit,
                box: box,
                rowArm: rowArm,
                columnArm: columnArm,
                near: near,
                far: far,
                target: target,
                externalUnit:
                    '第 ${linkRow + 1} 行 ${_cellLabel(near)}—${_cellLabel(far)}',
                connectedArm: columnArm,
                oppositeArm: rowArm,
              );
            }
          }
        }
      }
    }
    return null;
  }

  LogicalStep _emptyRectangleStep({
    required int digit,
    required int box,
    required List<CandidateRef> rowArm,
    required List<CandidateRef> columnArm,
    required int near,
    required int far,
    required int target,
    required String externalUnit,
    required List<CandidateRef> connectedArm,
    required List<CandidateRef> oppositeArm,
  }) {
    final nearCandidate = CandidateRef(near, digit);
    final farCandidate = CandidateRef(far, digit);
    return LogicalStep(
      technique: LogicalTechnique.emptyRectangle,
      pattern: {...rowArm, ...columnArm, nearCandidate, farCandidate}.toList(),
      eliminations: [CandidateRef(target, digit)],
      links: [
        LogicalLink(
          first: farCandidate,
          second: nearCandidate,
          strength: LogicalLinkStrength.strong,
        ),
      ],
      groupLinks: [
        LogicalGroupLink(
          firstGroup: [nearCandidate],
          secondGroup: connectedArm,
          strength: LogicalLinkStrength.weak,
        ),
        LogicalGroupLink(
          firstGroup: connectedArm,
          secondGroup: oppositeArm,
          strength: LogicalLinkStrength.strong,
        ),
      ],
      focus: '观察第 ${box + 1} 宫内候选 $digit 形成的行列交叉，以及$externalUnit的强链。',
      explanation:
          '第 ${box + 1} 宫的所有 $digit 都被限制在一条行臂和一条列臂上，两组候选构成分组强链。外部的 $externalUnit 又是强链：无论该强链哪端为真，${_cellLabel(target)} 的候选 $digit 都会被消去。',
    );
  }

  LogicalStep? _findWWing(List<int> masks) {
    final bivalueCells = [
      for (var index = 0; index < SudokuBoard.cellCount; index++)
        if (SudokuEngine.countBits(masks[index]) == 2) index,
    ];
    for (final wings in _combinations(bivalueCells, 2)) {
      final firstWing = wings[0];
      final secondWing = wings[1];
      final wingMask = masks[firstWing];
      if (wingMask != masks[secondWing] || _arePeers(firstWing, secondWing)) {
        continue;
      }
      final wingDigits = SudokuEngine.digitsInMask(wingMask);
      for (final linkDigit in wingDigits) {
        final eliminationDigit = wingDigits.firstWhere(
          (digit) => digit != linkDigit,
        );
        for (final strongPair in _conjugatePairs(masks, linkDigit)) {
          var firstLink = strongPair.$1;
          var secondLink = strongPair.$2;
          if ({firstWing, secondWing, firstLink, secondLink}.length != 4) {
            continue;
          }
          final direct =
              _arePeers(firstWing, firstLink) &&
              _arePeers(secondWing, secondLink);
          final reversed =
              _arePeers(firstWing, secondLink) &&
              _arePeers(secondWing, firstLink);
          if (!direct && !reversed) continue;
          if (!direct) {
            final temporary = firstLink;
            firstLink = secondLink;
            secondLink = temporary;
          }
          final eliminations = _commonPeerEliminations(
            masks: masks,
            digit: eliminationDigit,
            first: firstWing,
            second: secondWing,
            excludedIndices: {firstWing, secondWing, firstLink, secondLink},
          );
          if (eliminations.isEmpty) continue;

          final firstOuter = CandidateRef(firstWing, eliminationDigit);
          final firstInner = CandidateRef(firstWing, linkDigit);
          final firstLinkCandidate = CandidateRef(firstLink, linkDigit);
          final secondLinkCandidate = CandidateRef(secondLink, linkDigit);
          final secondInner = CandidateRef(secondWing, linkDigit);
          final secondOuter = CandidateRef(secondWing, eliminationDigit);
          return LogicalStep(
            technique: LogicalTechnique.wWing,
            pattern: [
              firstOuter,
              firstInner,
              firstLinkCandidate,
              secondLinkCandidate,
              secondInner,
              secondOuter,
            ],
            eliminations: eliminations,
            links: [
              LogicalLink(
                first: firstOuter,
                second: firstInner,
                strength: LogicalLinkStrength.strong,
              ),
              LogicalLink(
                first: firstInner,
                second: firstLinkCandidate,
                strength: LogicalLinkStrength.weak,
              ),
              LogicalLink(
                first: firstLinkCandidate,
                second: secondLinkCandidate,
                strength: LogicalLinkStrength.strong,
              ),
              LogicalLink(
                first: secondLinkCandidate,
                second: secondInner,
                strength: LogicalLinkStrength.weak,
              ),
              LogicalLink(
                first: secondInner,
                second: secondOuter,
                strength: LogicalLinkStrength.strong,
              ),
            ],
            focus:
                '观察 ${_cellLabel(firstWing)} 和 ${_cellLabel(secondWing)} 这两个同候选双值格，以及候选 $linkDigit 的外部强链。',
            explanation:
                '两个翼格都是 ${wingDigits.join('/')} 双值格，候选 $linkDigit 通过 ${_cellLabel(firstLink)}—${_cellLabel(secondLink)} 的强链连接。无论强链哪端为真，两翼中至少一格必须取 $eliminationDigit，所以同时看到两翼的格可删除 $eliminationDigit。',
          );
        }
      }
    }
    return null;
  }

  List<(int, int)> _conjugatePairs(List<int> masks, int digit) {
    final bit = SudokuEngine.bitFor(digit);
    final pairs = <(int, int)>{};
    for (final unit in SudokuEngine.allUnits) {
      final positions = [
        for (final index in unit)
          if ((masks[index] & bit) != 0) index,
      ];
      if (positions.length != 2) continue;
      final first = positions[0] < positions[1] ? positions[0] : positions[1];
      final second = positions[0] < positions[1] ? positions[1] : positions[0];
      pairs.add((first, second));
    }
    return pairs.toList();
  }

  LogicalStep? _findXYWing(List<int> values, List<int> masks) {
    final bivalueCells = [
      for (var index = 0; index < SudokuBoard.cellCount; index++)
        if (values[index] == 0 && SudokuEngine.countBits(masks[index]) == 2)
          index,
    ];
    for (final pivot in bivalueCells) {
      final pivotMask = masks[pivot];
      final wings = [
        for (final index in bivalueCells)
          if (index != pivot &&
              _arePeers(index, pivot) &&
              SudokuEngine.countBits(masks[index] & pivotMask) == 1)
            index,
      ];
      for (final pair in _combinations(wings, 2)) {
        final first = pair[0];
        final second = pair[1];
        final firstShared = masks[first] & pivotMask;
        final secondShared = masks[second] & pivotMask;
        if (firstShared == secondShared) continue;
        final firstOuter = masks[first] & ~pivotMask;
        final secondOuter = masks[second] & ~pivotMask;
        if (SudokuEngine.countBits(firstOuter) != 1 ||
            firstOuter != secondOuter) {
          continue;
        }
        final z = SudokuEngine.singleDigit(firstOuter);
        final eliminations = <CandidateRef>[];
        for (var index = 0; index < SudokuBoard.cellCount; index++) {
          if (index == pivot || index == first || index == second) continue;
          if (_arePeers(index, first) &&
              _arePeers(index, second) &&
              (masks[index] & firstOuter) != 0) {
            eliminations.add(CandidateRef(index, z));
          }
        }
        if (eliminations.isEmpty) continue;
        final pivotDigits = SudokuEngine.digitsInMask(pivotMask);
        return LogicalStep(
          technique: LogicalTechnique.xyWing,
          pattern: [
            for (final index in [pivot, first, second])
              for (final digit in SudokuEngine.digitsInMask(masks[index]))
                CandidateRef(index, digit),
          ],
          eliminations: eliminations,
          focus: '以 ${_cellLabel(pivot)} 为枢纽，观察两个高亮双候选格。',
          explanation:
              '枢纽格是 ${pivotDigits.join('/')}，两翼 ${_cellLabel(first)} 和 ${_cellLabel(second)} 共享候选 $z；无论枢纽取哪个数，至少一翼为 $z，因此同时看到两翼的格可删除 $z。',
        );
      }
    }
    return null;
  }

  static int _boxOf(int index) => (index ~/ 9) ~/ 3 * 3 + (index % 9) ~/ 3;

  static bool _arePeers(int first, int second) {
    if (first == second) return false;
    return first ~/ 9 == second ~/ 9 ||
        first % 9 == second % 9 ||
        _boxOf(first) == _boxOf(second);
  }

  static String _cellLabel(int index) =>
      '第 ${index ~/ 9 + 1} 行 ${index % 9 + 1} 列';

  static List<List<int>> _combinations(List<int> source, int size) {
    final result = <List<int>>[];

    void choose(int start, List<int> selected) {
      if (selected.length == size) {
        result.add(List<int>.of(selected));
        return;
      }
      final remaining = size - selected.length;
      for (var index = start; index <= source.length - remaining; index++) {
        selected.add(source[index]);
        choose(index + 1, selected);
        selected.removeLast();
      }
    }

    choose(0, <int>[]);
    return result;
  }

  static final List<_Unit> _units = [
    for (var index = 0; index < 9; index++)
      _Unit('第 ${index + 1} 行', SudokuEngine.rows[index]),
    for (var index = 0; index < 9; index++)
      _Unit('第 ${index + 1} 列', SudokuEngine.columns[index]),
    for (var index = 0; index < 9; index++)
      _Unit('第 ${index + 1} 宫', SudokuEngine.boxes[index]),
  ];
}

class _Unit {
  const _Unit(this.label, this.cells);

  final String label;
  final List<int> cells;
}
