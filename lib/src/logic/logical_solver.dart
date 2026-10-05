import '../model/sudoku_board.dart';
import 'sudoku_engine.dart';

enum PuzzleDifficulty { beginner, easy, medium, hard, expert, master }

extension PuzzleDifficultyInfo on PuzzleDifficulty {
  String get label => switch (this) {
    PuzzleDifficulty.beginner => '入门',
    PuzzleDifficulty.easy => '简单',
    PuzzleDifficulty.medium => '中等',
    PuzzleDifficulty.hard => '困难',
    PuzzleDifficulty.expert => '专家',
    PuzzleDifficulty.master => '骨灰',
  };

  String get description => switch (this) {
    PuzzleDifficulty.beginner => '唯余与宫行列摈除',
    PuzzleDifficulty.easy => '加入区块摈除和显性数对',
    PuzzleDifficulty.medium => '加入二至四数组和 X-Wing',
    PuzzleDifficulty.hard => '加入 Swordfish、翼和典型短链',
    PuzzleDifficulty.expert => '加入复杂鱼、染色和 X/XY-Chain',
    PuzzleDifficulty.master => '需要闭环、Grouped AIC 或 ALS-XZ',
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
  nakedQuad,
  hiddenPair,
  hiddenTriple,
  hiddenQuad,
  xWing,
  swordfish,
  jellyfish,
  finnedXWing,
  uniqueRectangleType1,
  uniqueRectangleType2,
  uniqueRectangleType3,
  uniqueRectangleType4,
  bugPlusOne,
  skyscraper,
  twoStringKite,
  emptyRectangle,
  wWing,
  xyWing,
  xyzWing,
  simpleColoringWrap,
  simpleColoringTrap,
  xChain,
  remotePair,
  xyChain,
  xCycle,
  discontinuousNiceLoop,
  continuousNiceLoop,
  aic,
  aicType2,
  groupedAic,
  groupedAicType2,
  groupedDiscontinuousNiceLoop,
  groupedContinuousNiceLoop,
  alsXZ,
  doublyLinkedAlsXZ,
}

extension LogicalTechniqueInfo on LogicalTechnique {
  String get label => switch (this) {
    LogicalTechnique.nakedSingle => '唯余',
    LogicalTechnique.hiddenSingle => '宫行列摈除',
    LogicalTechnique.lockedPointing => '宫区块摈除',
    LogicalTechnique.lockedClaiming => '行列区块摈除',
    LogicalTechnique.nakedPair => '显性数对',
    LogicalTechnique.nakedTriple => '显性三数组',
    LogicalTechnique.nakedQuad => '显性四数组',
    LogicalTechnique.hiddenPair => '隐性数对',
    LogicalTechnique.hiddenTriple => '隐性三数组',
    LogicalTechnique.hiddenQuad => '隐性四数组',
    LogicalTechnique.xWing => 'X-Wing',
    LogicalTechnique.swordfish => 'Swordfish',
    LogicalTechnique.jellyfish => 'Jellyfish',
    LogicalTechnique.finnedXWing => 'Finned X-Wing',
    LogicalTechnique.uniqueRectangleType1 => '唯一矩形 Type 1',
    LogicalTechnique.uniqueRectangleType2 => '唯一矩形 Type 2',
    LogicalTechnique.uniqueRectangleType3 => '唯一矩形 Type 3',
    LogicalTechnique.uniqueRectangleType4 => '唯一矩形 Type 4',
    LogicalTechnique.bugPlusOne => 'BUG+1',
    LogicalTechnique.skyscraper => '摩天楼',
    LogicalTechnique.twoStringKite => '双线风筝',
    LogicalTechnique.emptyRectangle => '空矩形',
    LogicalTechnique.wWing => 'W-Wing',
    LogicalTechnique.xyWing => 'XY-Wing',
    LogicalTechnique.xyzWing => 'XYZ-Wing',
    LogicalTechnique.simpleColoringWrap => '简单染色·同色矛盾',
    LogicalTechnique.simpleColoringTrap => '简单染色·双色夹击',
    LogicalTechnique.xChain => 'X-Chain',
    LogicalTechnique.remotePair => 'Remote Pairs',
    LogicalTechnique.xyChain => 'XY-Chain',
    LogicalTechnique.xCycle => 'X-Cycle',
    LogicalTechnique.discontinuousNiceLoop => '不连续 Nice Loop',
    LogicalTechnique.continuousNiceLoop => '连续 Nice Loop',
    LogicalTechnique.aic => 'AIC Type 1',
    LogicalTechnique.aicType2 => 'AIC Type 2',
    LogicalTechnique.groupedAic => 'Grouped AIC Type 1',
    LogicalTechnique.groupedAicType2 => 'Grouped AIC Type 2',
    LogicalTechnique.groupedDiscontinuousNiceLoop => '组节点不连续 Nice Loop',
    LogicalTechnique.groupedContinuousNiceLoop => '组节点连续 Nice Loop',
    LogicalTechnique.alsXZ => 'ALS-XZ',
    LogicalTechnique.doublyLinkedAlsXZ => '双链 ALS-XZ',
  };

  PuzzleDifficulty get difficulty => switch (this) {
    LogicalTechnique.nakedSingle ||
    LogicalTechnique.hiddenSingle => PuzzleDifficulty.beginner,
    LogicalTechnique.lockedPointing ||
    LogicalTechnique.lockedClaiming ||
    LogicalTechnique.nakedPair => PuzzleDifficulty.easy,
    LogicalTechnique.nakedTriple ||
    LogicalTechnique.nakedQuad ||
    LogicalTechnique.hiddenPair ||
    LogicalTechnique.hiddenTriple ||
    LogicalTechnique.hiddenQuad ||
    LogicalTechnique.xWing => PuzzleDifficulty.medium,
    LogicalTechnique.swordfish ||
    LogicalTechnique.uniqueRectangleType1 ||
    LogicalTechnique.uniqueRectangleType2 ||
    LogicalTechnique.uniqueRectangleType3 ||
    LogicalTechnique.uniqueRectangleType4 ||
    LogicalTechnique.bugPlusOne ||
    LogicalTechnique.skyscraper ||
    LogicalTechnique.twoStringKite ||
    LogicalTechnique.emptyRectangle ||
    LogicalTechnique.wWing ||
    LogicalTechnique.xyWing ||
    LogicalTechnique.xyzWing => PuzzleDifficulty.hard,
    LogicalTechnique.jellyfish ||
    LogicalTechnique.finnedXWing ||
    LogicalTechnique.simpleColoringWrap ||
    LogicalTechnique.simpleColoringTrap ||
    LogicalTechnique.xChain ||
    LogicalTechnique.remotePair ||
    LogicalTechnique.xyChain => PuzzleDifficulty.expert,
    LogicalTechnique.xCycle ||
    LogicalTechnique.discontinuousNiceLoop ||
    LogicalTechnique.continuousNiceLoop ||
    LogicalTechnique.aic ||
    LogicalTechnique.aicType2 ||
    LogicalTechnique.groupedAic ||
    LogicalTechnique.groupedAicType2 ||
    LogicalTechnique.groupedDiscontinuousNiceLoop ||
    LogicalTechnique.groupedContinuousNiceLoop ||
    LogicalTechnique.alsXZ ||
    LogicalTechnique.doublyLinkedAlsXZ => PuzzleDifficulty.master,
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

  @override
  String toString() => '($digit)r${index ~/ 9 + 1}c${index % 9 + 1}';
}

enum LogicalLinkStrength { strong, weak }

class LogicalLink {
  const LogicalLink({
    required this.first,
    required this.second,
    required this.strength,
    this.reason,
  });

  final CandidateRef first;
  final CandidateRef second;
  final LogicalLinkStrength strength;
  final String? reason;

  @override
  bool operator ==(Object other) =>
      other is LogicalLink &&
      other.first == first &&
      other.second == second &&
      other.strength == strength &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(first, second, strength, reason);
}

class LogicalGroupLink {
  const LogicalGroupLink({
    required this.firstGroup,
    required this.secondGroup,
    required this.strength,
    this.reason,
  });

  final List<CandidateRef> firstGroup;
  final List<CandidateRef> secondGroup;
  final LogicalLinkStrength strength;
  final String? reason;
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
    this.chainCells = const [],
    this.chainNodes = const [],
    this.chainGroups = const [],
    this.candidateColors = const {},
    this.isLoop = false,
  });

  final LogicalTechnique technique;
  final List<CandidateRef> pattern;
  final List<CandidateRef> eliminations;
  final int? placementIndex;
  final int? placementDigit;
  final List<LogicalLink> links;
  final List<LogicalGroupLink> groupLinks;
  final List<int> chainCells;
  final List<CandidateRef> chainNodes;
  final List<List<CandidateRef>> chainGroups;
  final Map<CandidateRef, int> candidateColors;
  final bool isLoop;
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

  int candidateColorMaskAt(int index, int color) {
    var mask = 0;
    for (final entry in candidateColors.entries) {
      if (entry.key.index == index && entry.value == color) {
        mask |= SudokuEngine.bitFor(entry.key.digit);
      }
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
    PuzzleDifficulty maxDifficulty = PuzzleDifficulty.master,
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
      step = _findNakedSubset(values, masks, 4);
      if (step != null) return step;
      step = _findHiddenSubset(values, masks, 4);
      if (step != null) return step;
      step = _findBasicFish(masks, 2);
      if (step != null) return step;
    }

    if (maxDifficulty.rank >= PuzzleDifficulty.hard.rank) {
      step = _findBasicFish(masks, 3);
      if (step != null) return step;
      step = _findUniqueRectangleType1(masks);
      if (step != null) return step;
      step = _findUniqueRectangleType2(masks);
      if (step != null) return step;
      step = _findUniqueRectangleType3(masks);
      if (step != null) return step;
      step = _findUniqueRectangleType4(masks);
      if (step != null) return step;
      step = _findBugPlusOne(masks);
      if (step != null) return step;
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
      step = _findXYZWing(values, masks);
      if (step != null) return step;
    }

    if (maxDifficulty.rank >= PuzzleDifficulty.expert.rank) {
      step = _findBasicFish(masks, 4);
      if (step != null) return step;
      step = _findFinnedXWing(masks);
      if (step != null) return step;
      step = _findRemotePair(values, masks);
      if (step != null) return step;
      step = _findSimpleColoring(masks, wrap: true);
      if (step != null) return step;
      step = _findSimpleColoring(masks, wrap: false);
      if (step != null) return step;
      step = _findXChain(masks);
      if (step != null) return step;
      step = _findXYChain(values, masks);
      if (step != null) return step;
    }

    if (maxDifficulty.rank >= PuzzleDifficulty.master.rank) {
      step = _findXCycle(masks);
      if (step != null) return step;
      step = _findNiceLoop(masks, continuous: false);
      if (step != null) return step;
      step = _findNiceLoop(masks, continuous: true);
      if (step != null) return step;
      step = _findAIC(masks);
      if (step != null) return step;
      step = _findAIC(masks, type2: true);
      if (step != null) return step;
      step = _findGroupedAIC(masks);
      if (step != null) return step;
      step = _findGroupedAIC(masks, type2: true);
      if (step != null) return step;
      step = _findGroupedNiceLoop(masks, continuous: false);
      if (step != null) return step;
      step = _findGroupedNiceLoop(masks, continuous: true);
      if (step != null) return step;
      step = _findAlsXZ(masks, doublyLinked: true);
      if (step != null) return step;
      step = _findAlsXZ(masks, doublyLinked: false);
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
      LogicalTechnique.nakedQuad => _findNakedSubset(values, masks, 4),
      LogicalTechnique.hiddenPair => _findHiddenSubset(values, masks, 2),
      LogicalTechnique.hiddenTriple => _findHiddenSubset(values, masks, 3),
      LogicalTechnique.hiddenQuad => _findHiddenSubset(values, masks, 4),
      LogicalTechnique.xWing => _findBasicFish(masks, 2),
      LogicalTechnique.swordfish => _findBasicFish(masks, 3),
      LogicalTechnique.jellyfish => _findBasicFish(masks, 4),
      LogicalTechnique.finnedXWing => _findFinnedXWing(masks),
      LogicalTechnique.uniqueRectangleType1 => _findUniqueRectangleType1(masks),
      LogicalTechnique.uniqueRectangleType2 => _findUniqueRectangleType2(masks),
      LogicalTechnique.uniqueRectangleType3 => _findUniqueRectangleType3(masks),
      LogicalTechnique.uniqueRectangleType4 => _findUniqueRectangleType4(masks),
      LogicalTechnique.bugPlusOne => _findBugPlusOne(masks),
      LogicalTechnique.skyscraper => _findSkyscraper(masks),
      LogicalTechnique.twoStringKite => _findTwoStringKite(masks),
      LogicalTechnique.emptyRectangle => _findEmptyRectangle(masks),
      LogicalTechnique.wWing => _findWWing(masks),
      LogicalTechnique.xyWing => _findXYWing(values, masks),
      LogicalTechnique.xyzWing => _findXYZWing(values, masks),
      LogicalTechnique.simpleColoringWrap => _findSimpleColoring(
        masks,
        wrap: true,
      ),
      LogicalTechnique.simpleColoringTrap => _findSimpleColoring(
        masks,
        wrap: false,
      ),
      LogicalTechnique.xChain => _findXChain(masks),
      LogicalTechnique.remotePair => _findRemotePair(values, masks),
      LogicalTechnique.xyChain => _findXYChain(values, masks),
      LogicalTechnique.xCycle => _findXCycle(masks),
      LogicalTechnique.discontinuousNiceLoop => _findNiceLoop(
        masks,
        continuous: false,
      ),
      LogicalTechnique.continuousNiceLoop => _findNiceLoop(
        masks,
        continuous: true,
      ),
      LogicalTechnique.aic => _findAIC(masks),
      LogicalTechnique.aicType2 => _findAIC(masks, type2: true),
      LogicalTechnique.groupedAic => _findGroupedAIC(masks),
      LogicalTechnique.groupedAicType2 => _findGroupedAIC(masks, type2: true),
      LogicalTechnique.groupedDiscontinuousNiceLoop => _findGroupedNiceLoop(
        masks,
        continuous: false,
      ),
      LogicalTechnique.groupedContinuousNiceLoop => _findGroupedNiceLoop(
        masks,
        continuous: true,
      ),
      LogicalTechnique.alsXZ => _findAlsXZ(masks, doublyLinked: false),
      LogicalTechnique.doublyLinkedAlsXZ => _findAlsXZ(
        masks,
        doublyLinked: true,
      ),
    };
  }

  LogicalSolveResult solve(
    List<int> source, {
    PuzzleDifficulty maxDifficulty = PuzzleDifficulty.master,
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
      solved:
          values.every((value) => value != 0) &&
          engine.validate(values) == null,
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
          technique: switch (size) {
            2 => LogicalTechnique.nakedPair,
            3 => LogicalTechnique.nakedTriple,
            4 => LogicalTechnique.nakedQuad,
            _ => throw ArgumentError.value(size, 'size'),
          },
          pattern: [
            for (final index in selected)
              for (final digit in SudokuEngine.digitsInMask(masks[index]))
                CandidateRef(index, digit),
          ],
          eliminations: eliminations,
          focus: '观察${unit.label}中 ${selected.map(_cellLabel).join('、')} 的候选数。',
          explanation:
              '这 ${_chineseCount(size)} 格只占用 ${digits.join('、')} 这 $size 个数，所以${unit.label}其他格可以删除这些候选。',
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
          technique: switch (size) {
            2 => LogicalTechnique.hiddenPair,
            3 => LogicalTechnique.hiddenTriple,
            4 => LogicalTechnique.hiddenQuad,
            _ => throw ArgumentError.value(size, 'size'),
          },
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

  LogicalStep? _findBasicFish(List<int> masks, int size) {
    for (var digit = 1; digit <= 9; digit++) {
      final bit = SudokuEngine.bitFor(digit);
      for (var rowBased = 0; rowBased < 2; rowBased++) {
        final positionsByBase = <int, List<int>>{};
        for (var base = 0; base < 9; base++) {
          final covers = [
            for (var cover = 0; cover < 9; cover++)
              if ((masks[rowBased == 0 ? base * 9 + cover : cover * 9 + base] &
                      bit) !=
                  0)
                cover,
          ];
          if (covers.length >= 2 && covers.length <= size) {
            positionsByBase[base] = covers;
          }
        }

        for (final bases in _combinations(
          positionsByBase.keys.toList(),
          size,
        )) {
          final covers = <int>{};
          for (final base in bases) {
            covers.addAll(positionsByBase[base]!);
          }
          if (covers.length != size) continue;

          final eliminations = <CandidateRef>[];
          for (final cover in covers) {
            for (var base = 0; base < 9; base++) {
              if (bases.contains(base)) continue;
              final index = rowBased == 0 ? base * 9 + cover : cover * 9 + base;
              if ((masks[index] & bit) != 0) {
                eliminations.add(CandidateRef(index, digit));
              }
            }
          }
          if (eliminations.isEmpty) continue;

          final technique = switch (size) {
            2 => LogicalTechnique.xWing,
            3 => LogicalTechnique.swordfish,
            4 => LogicalTechnique.jellyfish,
            _ => throw ArgumentError.value(size, 'size'),
          };
          final baseType = rowBased == 0 ? '行' : '列';
          final coverType = rowBased == 0 ? '列' : '行';
          final baseLabels = bases.map((index) => '${index + 1}').join('、');
          final coverLabels = covers.map((index) => '${index + 1}').join('、');
          return LogicalStep(
            technique: technique,
            pattern: [
              for (final base in bases)
                for (final cover in positionsByBase[base]!)
                  CandidateRef(
                    rowBased == 0 ? base * 9 + cover : cover * 9 + base,
                    digit,
                  ),
            ],
            eliminations: eliminations,
            focus: '观察第 $baseLabels $baseType中候选 $digit 所在的$coverType。',
            explanation:
                '这 $size 个$baseType中的候选 $digit 全部被限制在第 $coverLabels $coverType，形成 ${technique.label}，因此这些$coverType在其他$baseType中的候选 $digit 可以删除。',
          );
        }
      }
    }
    return null;
  }

  LogicalStep? _findFinnedXWing(List<int> masks) {
    for (var digit = 1; digit <= 9; digit++) {
      final bit = SudokuEngine.bitFor(digit);
      for (var rowBased = 0; rowBased < 2; rowBased++) {
        final positionsByBase = <int, List<int>>{};
        for (var base = 0; base < 9; base++) {
          positionsByBase[base] = [
            for (var cover = 0; cover < 9; cover++)
              if ((masks[rowBased == 0 ? base * 9 + cover : cover * 9 + base] &
                      bit) !=
                  0)
                cover,
          ];
        }

        for (var regularBase = 0; regularBase < 9; regularBase++) {
          final covers = positionsByBase[regularBase]!;
          if (covers.length != 2) continue;
          for (var finnedBase = 0; finnedBase < 9; finnedBase++) {
            if (finnedBase == regularBase) continue;
            final finnedPositions = positionsByBase[finnedBase]!;
            if (finnedPositions.length < 3 ||
                !covers.every(finnedPositions.contains)) {
              continue;
            }
            final fins = finnedPositions
                .where((position) => !covers.contains(position))
                .toList();

            for (final finnedCover in covers) {
              final corner = rowBased == 0
                  ? finnedBase * 9 + finnedCover
                  : finnedCover * 9 + finnedBase;
              final finBox = _boxOf(corner);
              if (!fins.every((position) {
                final index = rowBased == 0
                    ? finnedBase * 9 + position
                    : position * 9 + finnedBase;
                return _boxOf(index) == finBox;
              })) {
                continue;
              }

              final eliminations = <CandidateRef>[];
              for (final index in SudokuEngine.boxes[finBox]) {
                final base = rowBased == 0 ? index ~/ 9 : index % 9;
                final cover = rowBased == 0 ? index % 9 : index ~/ 9;
                if (base != regularBase &&
                    base != finnedBase &&
                    cover == finnedCover &&
                    (masks[index] & bit) != 0) {
                  eliminations.add(CandidateRef(index, digit));
                }
              }
              if (eliminations.isEmpty) continue;

              final baseType = rowBased == 0 ? '行' : '列';
              final coverType = rowBased == 0 ? '列' : '行';
              final finIndices = [
                for (final position in fins)
                  rowBased == 0
                      ? finnedBase * 9 + position
                      : position * 9 + finnedBase,
              ];
              final patternIndices = {
                for (final cover in covers)
                  rowBased == 0
                      ? regularBase * 9 + cover
                      : cover * 9 + regularBase,
                for (final cover in finnedPositions)
                  rowBased == 0
                      ? finnedBase * 9 + cover
                      : cover * 9 + finnedBase,
              };
              return LogicalStep(
                technique: LogicalTechnique.finnedXWing,
                pattern: [
                  for (final index in patternIndices)
                    CandidateRef(index, digit),
                ],
                eliminations: eliminations,
                focus:
                    '观察第 ${regularBase + 1}、${finnedBase + 1} $baseType的候选 $digit，以及 ${finIndices.map(_cellCoordinate).join('、')} 的鳍。',
                explanation:
                    '忽略鳍时两条$baseType在第 ${covers.map((cover) => cover + 1).join('、')} $coverType形成 X-Wing；若鳍成立，同宫约束也会得到相同结论，因此鳍所在宫与第 ${finnedCover + 1} $coverType交叉处的候选 $digit 可以删除。',
              );
            }
          }
        }
      }
    }
    return null;
  }

  LogicalStep? _findUniqueRectangleType1(List<int> masks) {
    for (final rows in _combinations(
      List<int>.generate(9, (index) => index),
      2,
    )) {
      for (final columns in _combinations(
        List<int>.generate(9, (index) => index),
        2,
      )) {
        final cells = [
          rows[0] * 9 + columns[0],
          rows[0] * 9 + columns[1],
          rows[1] * 9 + columns[0],
          rows[1] * 9 + columns[1],
        ];
        if (cells.map(_boxOf).toSet().length != 2 ||
            cells.any((index) => masks[index] == 0)) {
          continue;
        }

        for (final extraCell in cells) {
          final pairCells = cells.where((index) => index != extraCell).toList();
          final pairMask = masks[pairCells.first];
          if (SudokuEngine.countBits(pairMask) != 2 ||
              !pairCells.every((index) => masks[index] == pairMask) ||
              (masks[extraCell] & pairMask) != pairMask ||
              masks[extraCell] == pairMask) {
            continue;
          }
          final pairDigits = SudokuEngine.digitsInMask(pairMask);
          return LogicalStep(
            technique: LogicalTechnique.uniqueRectangleType1,
            pattern: [
              for (final index in cells)
                for (final digit in SudokuEngine.digitsInMask(masks[index]))
                  CandidateRef(index, digit),
            ],
            eliminations: [
              for (final digit in pairDigits) CandidateRef(extraCell, digit),
            ],
            focus: '观察 ${cells.map(_cellCoordinate).join('、')} 构成的两行、两列、两宫矩形。',
            explanation:
                '其中三格都只含 ${pairDigits.join('/')}。若第四格也取这两个数之一，四角会形成可互换的双解矩形；题目已验证唯一解，因此 ${_cellCoordinate(extraCell)} 必须使用额外候选，可以删除 ${pairDigits.join('、')}。',
          );
        }
      }
    }
    return null;
  }

  LogicalStep? _findUniqueRectangleType2(List<int> masks) {
    for (final rows in _combinations(
      List<int>.generate(9, (index) => index),
      2,
    )) {
      for (final columns in _combinations(
        List<int>.generate(9, (index) => index),
        2,
      )) {
        final cells = [
          rows[0] * 9 + columns[0],
          rows[0] * 9 + columns[1],
          rows[1] * 9 + columns[0],
          rows[1] * 9 + columns[1],
        ];
        if (cells.map(_boxOf).toSet().length != 2 ||
            cells.any((index) => masks[index] == 0)) {
          continue;
        }

        final sidePairs = <(List<int>, List<int>)>[
          ([cells[0], cells[1]], [cells[2], cells[3]]),
          ([cells[2], cells[3]], [cells[0], cells[1]]),
          ([cells[0], cells[2]], [cells[1], cells[3]]),
          ([cells[1], cells[3]], [cells[0], cells[2]]),
        ];
        for (final (floor, roof) in sidePairs) {
          final pairMask = masks[floor.first];
          if (SudokuEngine.countBits(pairMask) != 2 ||
              masks[floor.last] != pairMask) {
            continue;
          }
          final roofMask = masks[roof.first];
          if (roofMask != masks[roof.last] ||
              SudokuEngine.countBits(roofMask) != 3 ||
              (roofMask & pairMask) != pairMask) {
            continue;
          }
          final extraDigit = SudokuEngine.singleDigit(roofMask & ~pairMask);
          final eliminations = _commonPeerEliminations(
            masks: masks,
            digit: extraDigit,
            first: roof.first,
            second: roof.last,
            excludedIndices: cells.toSet(),
          );
          if (eliminations.isEmpty) continue;

          final pairDigits = SudokuEngine.digitsInMask(pairMask);
          return LogicalStep(
            technique: LogicalTechnique.uniqueRectangleType2,
            pattern: [
              for (final index in cells)
                for (final digit in SudokuEngine.digitsInMask(masks[index]))
                  CandidateRef(index, digit),
            ],
            eliminations: eliminations,
            focus:
                '观察 ${cells.map(_cellCoordinate).join('、')} 中带有共同额外候选 $extraDigit 的两个顶格。',
            explanation:
                '矩形底边两格都只含 ${pairDigits.join('/')}，顶边两格都是 ${pairDigits.join('/')}+$extraDigit。为避免四角落入可互换的双解矩形，两个顶格至少一格必须取 $extraDigit，因此同时看到它们的格可删除 $extraDigit。',
          );
        }
      }
    }
    return null;
  }

  LogicalStep? _findUniqueRectangleType3(List<int> masks) {
    for (final rows in _combinations(
      List<int>.generate(9, (index) => index),
      2,
    )) {
      for (final columns in _combinations(
        List<int>.generate(9, (index) => index),
        2,
      )) {
        final cells = [
          rows[0] * 9 + columns[0],
          rows[0] * 9 + columns[1],
          rows[1] * 9 + columns[0],
          rows[1] * 9 + columns[1],
        ];
        if (cells.map(_boxOf).toSet().length != 2 ||
            cells.any((index) => masks[index] == 0)) {
          continue;
        }

        final sidePairs = <(List<int>, List<int>)>[
          ([cells[0], cells[1]], [cells[2], cells[3]]),
          ([cells[2], cells[3]], [cells[0], cells[1]]),
          ([cells[0], cells[2]], [cells[1], cells[3]]),
          ([cells[1], cells[3]], [cells[0], cells[2]]),
        ];
        for (final (floor, roof) in sidePairs) {
          final pairMask = masks[floor.first];
          if (SudokuEngine.countBits(pairMask) != 2 ||
              masks[floor.last] != pairMask ||
              roof.any((index) => (masks[index] & pairMask) != pairMask)) {
            continue;
          }
          final roofExtraMasks = [
            for (final index in roof) masks[index] & ~pairMask,
          ];
          if (roofExtraMasks.any((mask) => mask == 0)) continue;
          final extraMask = roofExtraMasks[0] | roofExtraMasks[1];
          if (SudokuEngine.countBits(extraMask) < 2) continue;

          final sharedUnits = _units.where(
            (unit) =>
                unit.cells.contains(roof.first) &&
                unit.cells.contains(roof.last),
          );
          for (final unit in sharedUnits) {
            final availableCompanions = [
              for (final index in unit.cells)
                if (!cells.contains(index) &&
                    masks[index] != 0 &&
                    SudokuEngine.countBits(masks[index]) <= 4)
                  index,
            ];
            for (
              var companionCount = 1;
              companionCount <= 3;
              companionCount++
            ) {
              if (availableCompanions.length < companionCount) break;
              for (final companions in _combinations(
                availableCompanions,
                companionCount,
              )) {
                var subsetMask = extraMask;
                for (final index in companions) {
                  subsetMask |= masks[index];
                }
                final subsetSize = companionCount + 1;
                if (SudokuEngine.countBits(subsetMask) != subsetSize) continue;

                final protectedCells = {...cells, ...companions};
                final eliminations = <CandidateRef>[];
                for (final index in unit.cells) {
                  if (protectedCells.contains(index)) continue;
                  for (final digit in SudokuEngine.digitsInMask(
                    masks[index] & subsetMask,
                  )) {
                    eliminations.add(CandidateRef(index, digit));
                  }
                }
                if (eliminations.isEmpty) continue;

                final pairDigits = SudokuEngine.digitsInMask(pairMask);
                final extraDigits = SudokuEngine.digitsInMask(extraMask);
                final subsetDigits = SudokuEngine.digitsInMask(subsetMask);
                return LogicalStep(
                  technique: LogicalTechnique.uniqueRectangleType3,
                  pattern: [
                    for (final index in cells)
                      for (final digit in SudokuEngine.digitsInMask(
                        masks[index],
                      ))
                        CandidateRef(index, digit),
                    for (final index in companions)
                      for (final digit in SudokuEngine.digitsInMask(
                        masks[index],
                      ))
                        CandidateRef(index, digit),
                  ],
                  eliminations: eliminations,
                  focus:
                      '观察 ${cells.map(_cellCoordinate).join('、')} 的 ${pairDigits.join('/')} 唯一矩形，以及${unit.label}内的 ${companions.map(_cellCoordinate).join('、')}。',
                  explanation:
                      '两个顶格至少有一格必须使用额外候选 ${extraDigits.join('、')}，可将它们合并看成一个虚拟格。它与 ${companions.map(_cellCoordinate).join('、')} 共同形成候选 ${subsetDigits.join('、')} 的显性${_chineseCount(subsetSize)}数组，因此${unit.label}其他格可删除这些候选。',
                );
              }
            }
          }
        }
      }
    }
    return null;
  }

  LogicalStep? _findUniqueRectangleType4(List<int> masks) {
    for (final rows in _combinations(
      List<int>.generate(9, (index) => index),
      2,
    )) {
      for (final columns in _combinations(
        List<int>.generate(9, (index) => index),
        2,
      )) {
        final cells = [
          rows[0] * 9 + columns[0],
          rows[0] * 9 + columns[1],
          rows[1] * 9 + columns[0],
          rows[1] * 9 + columns[1],
        ];
        if (cells.map(_boxOf).toSet().length != 2 ||
            cells.any((index) => masks[index] == 0)) {
          continue;
        }

        final sidePairs = <(List<int>, List<int>)>[
          ([cells[0], cells[1]], [cells[2], cells[3]]),
          ([cells[2], cells[3]], [cells[0], cells[1]]),
          ([cells[0], cells[2]], [cells[1], cells[3]]),
          ([cells[1], cells[3]], [cells[0], cells[2]]),
        ];
        for (final (floor, roof) in sidePairs) {
          final pairMask = masks[floor.first];
          if (SudokuEngine.countBits(pairMask) != 2 ||
              masks[floor.last] != pairMask ||
              roof.any((index) => (masks[index] & pairMask) != pairMask) ||
              roof.every((index) => masks[index] == pairMask)) {
            continue;
          }
          final roofUnit = roof.first ~/ 9 == roof.last ~/ 9
              ? SudokuEngine.rows[roof.first ~/ 9]
              : SudokuEngine.columns[roof.first % 9];
          final pairDigits = SudokuEngine.digitsInMask(pairMask);
          for (final strongDigit in pairDigits) {
            final strongBit = SudokuEngine.bitFor(strongDigit);
            final strongPositions = [
              for (final index in roofUnit)
                if ((masks[index] & strongBit) != 0) index,
            ];
            if (strongPositions.length != 2 ||
                strongPositions.toSet().difference(roof.toSet()).isNotEmpty) {
              continue;
            }
            final removeDigit = pairDigits.firstWhere(
              (digit) => digit != strongDigit,
            );
            final eliminations = [
              for (final index in roof)
                if ((masks[index] & SudokuEngine.bitFor(removeDigit)) != 0)
                  CandidateRef(index, removeDigit),
            ];
            if (eliminations.isEmpty) continue;

            return LogicalStep(
              technique: LogicalTechnique.uniqueRectangleType4,
              pattern: [
                for (final index in cells)
                  for (final digit in SudokuEngine.digitsInMask(masks[index]))
                    CandidateRef(index, digit),
              ],
              eliminations: eliminations,
              links: [
                LogicalLink(
                  first: CandidateRef(roof.first, strongDigit),
                  second: CandidateRef(roof.last, strongDigit),
                  strength: LogicalLinkStrength.strong,
                  reason: '该行或列的候选 $strongDigit 只剩这两处',
                ),
              ],
              focus:
                  '观察 ${cells.map(_cellCoordinate).join('、')} 的唯一矩形，以及顶格之间的候选 $strongDigit 强链。',
              explanation:
                  '两个顶格中的 $strongDigit 在所在行或列形成强链，必有一格取 $strongDigit。若另一个矩形候选 $removeDigit 也留在顶格，会允许四角构成可互换的双解，因此两个顶格都可删除 $removeDigit。',
            );
          }
        }
      }
    }
    return null;
  }

  LogicalStep? _findBugPlusOne(List<int> masks) {
    final unsolved = [
      for (var index = 0; index < SudokuBoard.cellCount; index++)
        if (masks[index] != 0) index,
    ];
    final pivotCells = [
      for (final index in unsolved)
        if (SudokuEngine.countBits(masks[index]) == 3) index,
    ];
    if (pivotCells.length != 1 ||
        unsolved.any(
          (index) =>
              index != pivotCells.single &&
              SudokuEngine.countBits(masks[index]) != 2,
        )) {
      return null;
    }

    final pivot = pivotCells.single;
    final pivotUnits = <List<int>>[
      SudokuEngine.rows[pivot ~/ 9],
      SudokuEngine.columns[pivot % 9],
      SudokuEngine.boxes[_boxOf(pivot)],
    ];
    final possibleExtras = <int>[];
    for (final digit in SudokuEngine.digitsInMask(masks[pivot])) {
      final bit = SudokuEngine.bitFor(digit);
      if (pivotUnits.every(
        (unit) => unit.where((index) => (masks[index] & bit) != 0).length == 3,
      )) {
        possibleExtras.add(digit);
      }
    }
    if (possibleExtras.length != 1) return null;
    final extraDigit = possibleExtras.single;

    for (final unit in SudokuEngine.allUnits) {
      for (var digit = 1; digit <= 9; digit++) {
        final bit = SudokuEngine.bitFor(digit);
        final count = unit.where((index) => (masks[index] & bit) != 0).length;
        final isExtraOccurrence = digit == extraDigit && unit.contains(pivot);
        if (isExtraOccurrence ? count != 3 : count != 0 && count != 2) {
          return null;
        }
      }
    }

    return LogicalStep(
      technique: LogicalTechnique.bugPlusOne,
      pattern: [
        for (final digit in SudokuEngine.digitsInMask(masks[pivot]))
          CandidateRef(pivot, digit),
      ],
      eliminations: const [],
      placementIndex: pivot,
      placementDigit: extraDigit,
      focus: '观察唯一的三候选格 ${_cellCoordinate(pivot)}，其余空格都是双值格。',
      explanation:
          '若不放置额外候选 $extraDigit，整个盘面会成为每个候选在相关行、列、宫都出现两次的 BUG 双解结构。题目已验证唯一解，因此 ${_cellCoordinate(pivot)} 必须填 $extraDigit。',
    );
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
        final firstSharedDigit = SudokuEngine.singleDigit(firstShared);
        final secondSharedDigit = SudokuEngine.singleDigit(secondShared);
        return LogicalStep(
          technique: LogicalTechnique.xyWing,
          pattern: [
            for (final index in [pivot, first, second])
              for (final digit in SudokuEngine.digitsInMask(masks[index]))
                CandidateRef(index, digit),
          ],
          eliminations: eliminations,
          links: [
            LogicalLink(
              first: CandidateRef(first, z),
              second: CandidateRef(first, firstSharedDigit),
              strength: LogicalLinkStrength.strong,
            ),
            LogicalLink(
              first: CandidateRef(first, firstSharedDigit),
              second: CandidateRef(pivot, firstSharedDigit),
              strength: LogicalLinkStrength.weak,
            ),
            LogicalLink(
              first: CandidateRef(pivot, firstSharedDigit),
              second: CandidateRef(pivot, secondSharedDigit),
              strength: LogicalLinkStrength.strong,
            ),
            LogicalLink(
              first: CandidateRef(pivot, secondSharedDigit),
              second: CandidateRef(second, secondSharedDigit),
              strength: LogicalLinkStrength.weak,
            ),
            LogicalLink(
              first: CandidateRef(second, secondSharedDigit),
              second: CandidateRef(second, z),
              strength: LogicalLinkStrength.strong,
            ),
          ],
          chainCells: [first, pivot, second],
          focus: '以 ${_cellLabel(pivot)} 为枢纽，观察两个高亮双候选格。',
          explanation:
              '枢纽格是 ${pivotDigits.join('/')}，两翼 ${_cellLabel(first)} 和 ${_cellLabel(second)} 共享候选 $z；无论枢纽取哪个数，至少一翼为 $z，因此同时看到两翼的格可删除 $z。',
        );
      }
    }
    return null;
  }

  LogicalStep? _findXYZWing(List<int> values, List<int> masks) {
    final pivots = [
      for (var index = 0; index < SudokuBoard.cellCount; index++)
        if (values[index] == 0 && SudokuEngine.countBits(masks[index]) == 3)
          index,
    ];
    final bivalueCells = [
      for (var index = 0; index < SudokuBoard.cellCount; index++)
        if (values[index] == 0 && SudokuEngine.countBits(masks[index]) == 2)
          index,
    ];

    for (final pivot in pivots) {
      final pivotMask = masks[pivot];
      final wings = [
        for (final index in bivalueCells)
          if (_arePeers(index, pivot) && (masks[index] & ~pivotMask) == 0)
            index,
      ];
      for (final pair in _combinations(wings, 2)) {
        final first = pair[0];
        final second = pair[1];
        final sharedMask = masks[first] & masks[second];
        if (SudokuEngine.countBits(sharedMask) != 1 ||
            (masks[first] | masks[second]) != pivotMask) {
          continue;
        }
        final z = SudokuEngine.singleDigit(sharedMask);
        final eliminations = <CandidateRef>[];
        for (var index = 0; index < SudokuBoard.cellCount; index++) {
          if (index == pivot || index == first || index == second) continue;
          if ((masks[index] & sharedMask) != 0 &&
              _arePeers(index, pivot) &&
              _arePeers(index, first) &&
              _arePeers(index, second)) {
            eliminations.add(CandidateRef(index, z));
          }
        }
        if (eliminations.isEmpty) continue;

        final pivotDigits = SudokuEngine.digitsInMask(pivotMask);
        return LogicalStep(
          technique: LogicalTechnique.xyzWing,
          pattern: [
            for (final index in [pivot, first, second])
              for (final digit in SudokuEngine.digitsInMask(masks[index]))
                CandidateRef(index, digit),
          ],
          eliminations: eliminations,
          focus: '以 ${_cellLabel(pivot)} 的三候选格为枢纽，观察两个高亮双值翼。',
          explanation:
              '枢纽格包含 ${pivotDigits.join('/')}，两翼分别位于 ${_cellLabel(first)} 和 ${_cellLabel(second)}，三格无论如何至少有一格为 $z；同时看到枢纽和两翼的格可以删除候选 $z。',
        );
      }
    }
    return null;
  }

  LogicalStep? _findRemotePair(
    List<int> values,
    List<int> masks, {
    int maxCells = 8,
    int maxStates = 50000,
  }) {
    final cellsByPair = <int, List<int>>{};
    for (var index = 0; index < SudokuBoard.cellCount; index++) {
      if (values[index] != 0 || SudokuEngine.countBits(masks[index]) != 2) {
        continue;
      }
      cellsByPair.putIfAbsent(masks[index], () => <int>[]).add(index);
    }

    for (final entry in cellsByPair.entries) {
      final pairMask = entry.key;
      final pairCells = entry.value;
      if (pairCells.length < 4) continue;
      final queue = <List<int>>[
        for (final index in pairCells) [index],
      ];
      var cursor = 0;
      var examinedStates = 0;
      while (cursor < queue.length && examinedStates < maxStates) {
        final path = queue[cursor++];
        examinedStates++;
        if (path.length >= 4 &&
            path.length.isEven &&
            !_arePeers(path.first, path.last)) {
          final eliminations = <CandidateRef>{};
          for (final digit in SudokuEngine.digitsInMask(pairMask)) {
            eliminations.addAll(
              _commonPeerEliminations(
                masks: masks,
                digit: digit,
                first: path.first,
                second: path.last,
                excludedIndices: path.toSet(),
              ),
            );
          }
          if (eliminations.isNotEmpty) {
            return _remotePairStep(
              path: path,
              pairMask: pairMask,
              eliminations: eliminations.toList(),
            );
          }
        }

        if (path.length >= maxCells) continue;
        for (final next in pairCells) {
          if (path.contains(next) || !_arePeers(path.last, next)) continue;
          queue.add([...path, next]);
        }
      }
    }
    return null;
  }

  LogicalStep _remotePairStep({
    required List<int> path,
    required int pairMask,
    required List<CandidateRef> eliminations,
  }) {
    final pairDigits = SudokuEngine.digitsInMask(pairMask);
    final links = <LogicalLink>[];
    final chainNodes = <CandidateRef>[];
    var incomingDigit = pairDigits.first;
    for (var position = 0; position < path.length; position++) {
      final cell = path[position];
      final outgoingDigit = pairDigits.firstWhere(
        (digit) => digit != incomingDigit,
      );
      if (position == 0) {
        chainNodes.add(CandidateRef(cell, incomingDigit));
      }
      chainNodes.add(CandidateRef(cell, outgoingDigit));
      links.add(
        LogicalLink(
          first: CandidateRef(cell, incomingDigit),
          second: CandidateRef(cell, outgoingDigit),
          strength: LogicalLinkStrength.strong,
          reason: '${_cellCoordinate(cell)} 是 ${pairDigits.join('/')} 双值格',
        ),
      );
      if (position < path.length - 1) {
        final next = path[position + 1];
        chainNodes.add(CandidateRef(next, outgoingDigit));
        links.add(
          LogicalLink(
            first: CandidateRef(cell, outgoingDigit),
            second: CandidateRef(next, outgoingDigit),
            strength: LogicalLinkStrength.weak,
            reason:
                '${_cellCoordinate(cell)} 与 ${_cellCoordinate(next)} 互看，候选 $outgoingDigit 不能同时成立',
          ),
        );
      }
      incomingDigit = outgoingDigit;
    }

    return LogicalStep(
      technique: LogicalTechnique.remotePair,
      pattern: [
        for (final index in path)
          for (final digit in pairDigits) CandidateRef(index, digit),
      ],
      eliminations: eliminations,
      links: links,
      chainCells: path,
      chainNodes: chainNodes,
      focus:
          '沿 ${path.map(_cellCoordinate).join(' → ')} 追踪相同的 ${pairDigits.join('/')} 双值格。',
      explanation:
          '链上每个双值格都与前一格取相反的值，因此两个链端的 ${pairDigits.join('/')} 极性相反。同时看到两个链端的格，无论哪种排列成立，都不能再取 ${pairDigits.join('、')}。',
    );
  }

  LogicalStep? _findSimpleColoring(List<int> masks, {required bool wrap}) {
    for (var digit = 1; digit <= 9; digit++) {
      final bit = SudokuEngine.bitFor(digit);
      final graph = <int, Set<int>>{};
      for (final unit in SudokuEngine.allUnits) {
        final positions = [
          for (final index in unit)
            if ((masks[index] & bit) != 0) index,
        ];
        if (positions.length != 2) continue;
        graph.putIfAbsent(positions[0], () => <int>{}).add(positions[1]);
        graph.putIfAbsent(positions[1], () => <int>{}).add(positions[0]);
      }

      final visited = <int>{};
      for (final start in graph.keys) {
        if (!visited.add(start)) continue;
        final colors = <int, int>{start: 0};
        final queue = <int>[start];
        for (var cursor = 0; cursor < queue.length; cursor++) {
          final current = queue[cursor];
          for (final next in graph[current] ?? const <int>{}) {
            if (!colors.containsKey(next)) {
              colors[next] = 1 - colors[current]!;
              visited.add(next);
              queue.add(next);
            }
          }
        }
        if (colors.length < 3) continue;

        final component = colors.keys.toSet();
        final links = <LogicalLink>[];
        final linkedPairs = <(int, int)>{};
        for (final first in component) {
          for (final second in graph[first] ?? const <int>{}) {
            if (!component.contains(second)) continue;
            final low = first < second ? first : second;
            final high = first < second ? second : first;
            if (!linkedPairs.add((low, high))) continue;
            links.add(
              LogicalLink(
                first: CandidateRef(first, digit),
                second: CandidateRef(second, digit),
                strength: LogicalLinkStrength.strong,
                reason: '候选 $digit 在该行、列或宫内只剩这两处',
              ),
            );
          }
        }

        if (wrap) {
          int? falseColor;
          List<int>? conflict;
          final nodes = component.toList();
          for (
            var first = 0;
            first < nodes.length && conflict == null;
            first++
          ) {
            for (var second = first + 1; second < nodes.length; second++) {
              if (colors[nodes[first]] == colors[nodes[second]] &&
                  _arePeers(nodes[first], nodes[second])) {
                falseColor = colors[nodes[first]];
                conflict = [nodes[first], nodes[second]];
                break;
              }
            }
          }
          if (conflict == null) continue;
          final eliminations = [
            for (final entry in colors.entries)
              if (entry.value == falseColor) CandidateRef(entry.key, digit),
          ];
          return LogicalStep(
            technique: LogicalTechnique.simpleColoringWrap,
            pattern: [
              for (final index in component) CandidateRef(index, digit),
            ],
            eliminations: eliminations,
            links: links,
            chainCells: component.toList(),
            candidateColors: {
              for (final entry in colors.entries)
                CandidateRef(entry.key, digit): entry.value,
            },
            focus:
                '沿候选 $digit 的强链交替染两色，观察 ${conflict.map(_cellCoordinate).join('、')}。',
            explanation:
                '这两格被染成同一色，却处于同一行、列或宫，不可能同时为真。因此该颜色整体为假，所有同色格都可删除候选 $digit。',
          );
        }

        final colorZero = [
          for (final entry in colors.entries)
            if (entry.value == 0) entry.key,
        ];
        final colorOne = [
          for (final entry in colors.entries)
            if (entry.value == 1) entry.key,
        ];
        final eliminations = <CandidateRef>[];
        for (var index = 0; index < SudokuBoard.cellCount; index++) {
          if (component.contains(index) || (masks[index] & bit) == 0) continue;
          if (colorZero.any((node) => _arePeers(index, node)) &&
              colorOne.any((node) => _arePeers(index, node))) {
            eliminations.add(CandidateRef(index, digit));
          }
        }
        if (eliminations.isEmpty) continue;
        return LogicalStep(
          technique: LogicalTechnique.simpleColoringTrap,
          pattern: [for (final index in component) CandidateRef(index, digit)],
          eliminations: eliminations,
          links: links,
          chainCells: component.toList(),
          candidateColors: {
            for (final entry in colors.entries)
              CandidateRef(entry.key, digit): entry.value,
          },
          focus: '沿候选 $digit 的强链交替染两色，再查找同时看到两种颜色的格。',
          explanation:
              '强链两端必有一端成立，所以这个连通链的两种颜色必有一色为真。被高亮删除的格同时看到两种颜色，无论哪色为真都不能取 $digit。',
        );
      }
    }
    return null;
  }

  LogicalStep? _findXChain(
    List<int> masks, {
    int minLinks = 5,
    int maxLinks = 11,
    int maxStates = 100000,
  }) {
    final graph = _buildAICGraph(masks);
    var examinedStates = 0;
    for (var digit = 1; digit <= 9; digit++) {
      if (examinedStates >= maxStates) break;
      final starts = graph.entries
          .where(
            (entry) =>
                entry.key.digit == digit &&
                entry.value.any(
                  (edge) =>
                      edge.to.digit == digit &&
                      edge.strength == LogicalLinkStrength.strong,
                ),
          )
          .map((entry) => entry.key)
          .toList();
      final queue = <_AICState>[
        for (final start in starts)
          _AICState(
            nodes: [start],
            links: const [],
            nextStrength: LogicalLinkStrength.strong,
          ),
      ];
      var cursor = 0;
      while (cursor < queue.length && examinedStates < maxStates) {
        final state = queue[cursor++];
        examinedStates++;
        final current = state.nodes.last;
        for (final edge in graph[current] ?? const <_AICEdge>[]) {
          if (edge.to.digit != digit ||
              edge.strength != state.nextStrength ||
              state.nodes.contains(edge.to)) {
            continue;
          }
          final nodes = [...state.nodes, edge.to];
          final links = [
            ...state.links,
            LogicalLink(
              first: current,
              second: edge.to,
              strength: edge.strength,
              reason: edge.reason,
            ),
          ];
          final nextStrength = edge.strength == LogicalLinkStrength.strong
              ? LogicalLinkStrength.weak
              : LogicalLinkStrength.strong;

          if (edge.strength == LogicalLinkStrength.strong &&
              links.length >= minLinks) {
            final eliminations = _commonPeerEliminations(
              masks: masks,
              digit: digit,
              first: nodes.first.index,
              second: nodes.last.index,
              excludedIndices: nodes.map((node) => node.index).toSet(),
            );
            if (eliminations.isNotEmpty) {
              return LogicalStep(
                technique: LogicalTechnique.xChain,
                pattern: nodes,
                eliminations: eliminations,
                links: links,
                chainCells: nodes.map((node) => node.index).toSet().toList(),
                chainNodes: nodes,
                focus:
                    '从 ($digit)${_cellCoordinate(nodes.first.index)} 出发，沿同一候选数的强弱关系交替追踪到 ($digit)${_cellCoordinate(nodes.last.index)}。',
                explanation:
                    'X-Chain 以强链开始并以强链结束，中间强、弱链交替，因此两个端点至少有一处必须是 $digit。同时看到两个端点的格可删除候选 $digit。',
              );
            }
          }

          if (links.length < maxLinks) {
            queue.add(
              _AICState(nodes: nodes, links: links, nextStrength: nextStrength),
            );
          }
        }
      }
    }
    return null;
  }

  LogicalStep? _findXYChain(
    List<int> values,
    List<int> masks, {
    int maxCells = 8,
    int maxStates = 50000,
  }) {
    final bivalueCells = [
      for (var index = 0; index < SudokuBoard.cellCount; index++)
        if (values[index] == 0 && SudokuEngine.countBits(masks[index]) == 2)
          index,
    ];
    if (bivalueCells.length < 4) return null;

    final cellsByDigit = List<List<int>>.generate(10, (_) => <int>[]);
    for (final index in bivalueCells) {
      for (final digit in SudokuEngine.digitsInMask(masks[index])) {
        cellsByDigit[digit].add(index);
      }
    }

    final queue = <_XYChainState>[];
    for (final index in bivalueCells) {
      final digits = SudokuEngine.digitsInMask(masks[index]);
      queue.add(
        _XYChainState(
          path: [index],
          startDigit: digits[0],
          outgoingDigit: digits[1],
        ),
      );
      queue.add(
        _XYChainState(
          path: [index],
          startDigit: digits[1],
          outgoingDigit: digits[0],
        ),
      );
    }

    var cursor = 0;
    var examinedStates = 0;
    while (cursor < queue.length && examinedStates < maxStates) {
      final state = queue[cursor++];
      examinedStates++;
      final current = state.path.last;
      for (final next in cellsByDigit[state.outgoingDigit]) {
        if (state.path.contains(next) || !_arePeers(current, next)) continue;
        final nextMask = masks[next];
        final nextOutgoingMask =
            nextMask & ~SudokuEngine.bitFor(state.outgoingDigit);
        if (SudokuEngine.countBits(nextOutgoingMask) != 1) continue;
        final nextOutgoing = SudokuEngine.singleDigit(nextOutgoingMask);
        final nextPath = [...state.path, next];

        if (nextPath.length >= 4 && nextOutgoing == state.startDigit) {
          final eliminations = _commonPeerEliminations(
            masks: masks,
            digit: state.startDigit,
            first: nextPath.first,
            second: nextPath.last,
            excludedIndices: nextPath.toSet(),
          );
          if (eliminations.isNotEmpty) {
            return _xyChainStep(
              path: nextPath,
              startDigit: state.startDigit,
              masks: masks,
              eliminations: eliminations,
            );
          }
        }

        if (nextPath.length < maxCells) {
          queue.add(
            _XYChainState(
              path: nextPath,
              startDigit: state.startDigit,
              outgoingDigit: nextOutgoing,
            ),
          );
        }
      }
    }
    return null;
  }

  LogicalStep _xyChainStep({
    required List<int> path,
    required int startDigit,
    required List<int> masks,
    required List<CandidateRef> eliminations,
  }) {
    final links = <LogicalLink>[];
    final chainNodes = <CandidateRef>[];
    var incomingDigit = startDigit;
    for (var position = 0; position < path.length; position++) {
      final cell = path[position];
      final outgoingMask = masks[cell] & ~SudokuEngine.bitFor(incomingDigit);
      final outgoingDigit = SudokuEngine.singleDigit(outgoingMask);
      if (position == 0) {
        chainNodes.add(CandidateRef(cell, incomingDigit));
      }
      chainNodes.add(CandidateRef(cell, outgoingDigit));
      links.add(
        LogicalLink(
          first: CandidateRef(cell, incomingDigit),
          second: CandidateRef(cell, outgoingDigit),
          strength: LogicalLinkStrength.strong,
        ),
      );
      if (position < path.length - 1) {
        chainNodes.add(CandidateRef(path[position + 1], outgoingDigit));
        links.add(
          LogicalLink(
            first: CandidateRef(cell, outgoingDigit),
            second: CandidateRef(path[position + 1], outgoingDigit),
            strength: LogicalLinkStrength.weak,
          ),
        );
      }
      incomingDigit = outgoingDigit;
    }

    final chainDescription = path
        .map(
          (index) =>
              '${_cellCoordinate(index)}(${SudokuEngine.digitsInMask(masks[index]).join('/')})',
        )
        .join(' → ');
    return LogicalStep(
      technique: LogicalTechnique.xyChain,
      pattern: [
        for (final index in path)
          for (final digit in SudokuEngine.digitsInMask(masks[index]))
            CandidateRef(index, digit),
      ],
      eliminations: eliminations,
      links: links,
      chainCells: path,
      chainNodes: chainNodes,
      focus:
          '从 ${_cellLabel(path.first)} 的候选 $startDigit 出发，沿 ${path.length} 个高亮双值格追踪链条。',
      explanation:
          '链条顺序：$chainDescription。每个双值格内部是强链，相邻格的共同候选是弱链；如果起点的 $startDigit 为假，推导到终点的 $startDigit 就必为真，因此两端至少一端为 $startDigit，同时看到两端的格可删除该候选。',
    );
  }

  LogicalStep? _findXCycle(
    List<int> masks, {
    int maxLinks = 12,
    int maxStates = 120000,
  }) => _findAlternatingLoop(
    masks,
    mode: _LoopMode.xCycle,
    maxLinks: maxLinks,
    maxStates: maxStates,
  );

  LogicalStep? _findNiceLoop(
    List<int> masks, {
    required bool continuous,
    int maxLinks = 12,
    int maxStates = 160000,
  }) {
    if (continuous) {
      return _findAlternatingLoop(
        masks,
        mode: _LoopMode.continuousNiceLoop,
        maxLinks: maxLinks,
        maxStates: maxStates,
      );
    }
    return _findAlternatingLoop(
          masks,
          mode: _LoopMode.discontinuousNiceLoop,
          initialStrength: LogicalLinkStrength.strong,
          maxLinks: maxLinks,
          maxStates: maxStates,
        ) ??
        _findAlternatingLoop(
          masks,
          mode: _LoopMode.discontinuousNiceLoop,
          initialStrength: LogicalLinkStrength.weak,
          maxLinks: maxLinks,
          maxStates: maxStates,
        );
  }

  LogicalStep? _findAlternatingLoop(
    List<int> masks, {
    required _LoopMode mode,
    required int maxLinks,
    required int maxStates,
    LogicalLinkStrength? initialStrength,
  }) {
    final graph = _buildAICGraph(masks);
    final sameDigitOnly = mode == _LoopMode.xCycle;
    final initialStrengths = initialStrength != null
        ? [initialStrength]
        : mode == _LoopMode.continuousNiceLoop
        ? const [LogicalLinkStrength.strong]
        : LogicalLinkStrength.values;
    final queue = <_AICState>[];

    for (final start in graph.keys) {
      for (final strength in initialStrengths) {
        if ((graph[start] ?? const <_AICEdge>[]).any(
          (edge) =>
              edge.strength == strength &&
              (!sameDigitOnly || edge.to.digit == start.digit),
        )) {
          queue.add(
            _AICState(nodes: [start], links: const [], nextStrength: strength),
          );
        }
      }
    }

    var cursor = 0;
    var examinedStates = 0;
    var enqueuedStates = queue.length;
    while (cursor < queue.length && examinedStates < maxStates) {
      final state = queue[cursor++];
      examinedStates++;
      final start = state.nodes.first;
      final current = state.nodes.last;
      for (final edge in graph[current] ?? const <_AICEdge>[]) {
        if (edge.strength != state.nextStrength ||
            (sameDigitOnly && edge.to.digit != start.digit)) {
          continue;
        }

        final link = LogicalLink(
          first: current,
          second: edge.to,
          strength: edge.strength,
          reason: edge.reason,
        );
        if (edge.to == start) {
          final linkCount = state.links.length + 1;
          if (linkCount < 4 || state.links.isEmpty) continue;
          final closesContinuously =
              edge.strength != state.links.first.strength;
          if (mode == _LoopMode.continuousNiceLoop && !closesContinuously) {
            continue;
          }
          if (mode == _LoopMode.discontinuousNiceLoop && closesContinuously) {
            continue;
          }
          if (!closesContinuously && linkCount < 5) continue;
          if (!sameDigitOnly &&
              state.nodes.map((node) => node.digit).toSet().length < 2) {
            continue;
          }

          final links = [...state.links, link];
          final step = _loopStep(
            masks: masks,
            mode: mode,
            nodes: state.nodes,
            links: links,
            continuous: closesContinuously,
          );
          if (step != null) return step;
          continue;
        }

        if (state.nodes.contains(edge.to) ||
            state.links.length + 1 >= maxLinks ||
            enqueuedStates >= maxStates) {
          continue;
        }
        final nextStrength = edge.strength == LogicalLinkStrength.strong
            ? LogicalLinkStrength.weak
            : LogicalLinkStrength.strong;
        queue.add(
          _AICState(
            nodes: [...state.nodes, edge.to],
            links: [...state.links, link],
            nextStrength: nextStrength,
          ),
        );
        enqueuedStates++;
      }
    }
    return null;
  }

  LogicalStep? _loopStep({
    required List<int> masks,
    required _LoopMode mode,
    required List<CandidateRef> nodes,
    required List<LogicalLink> links,
    required bool continuous,
  }) {
    final start = nodes.first;
    final technique = switch (mode) {
      _LoopMode.xCycle => LogicalTechnique.xCycle,
      _LoopMode.discontinuousNiceLoop => LogicalTechnique.discontinuousNiceLoop,
      _LoopMode.continuousNiceLoop => LogicalTechnique.continuousNiceLoop,
    };
    final pattern = nodes.toSet().toList();
    final chainCells = nodes.map((node) => node.index).toSet().toList();

    if (continuous) {
      final eliminations = _continuousLoopEliminations(
        masks: masks,
        nodes: nodes,
        links: links,
      );
      if (eliminations.isEmpty) return null;
      final weakLinkCount = links
          .where((link) => link.strength == LogicalLinkStrength.weak)
          .length;
      return LogicalStep(
        technique: technique,
        pattern: pattern,
        eliminations: eliminations,
        links: links,
        chainCells: chainCells,
        chainNodes: nodes,
        isLoop: true,
        focus: mode == _LoopMode.xCycle
            ? '沿候选 ${start.digit} 的强链、弱链交替追踪，直到回到起点。'
            : '从 (${start.digit})${_cellCoordinate(start.index)} 出发，沿强弱链交替追踪并闭合成环。',
        explanation: mode == _LoopMode.xCycle
            ? 'X-Cycle 在同一候选数上完整交替闭合。环上的 $weakLinkCount 条弱链都有一端必然成立，因此同时与某条弱链两端冲突的其他候选 ${start.digit} 可以删除。'
            : '这是一个强弱链完整交替的连续闭环。环上的 $weakLinkCount 条弱链都可视为“至少一端成立”，所以同时与其两端冲突的其他候选都可删除。',
      );
    }

    final discontinuity = links.first.strength;
    if (discontinuity == LogicalLinkStrength.strong) {
      return LogicalStep(
        technique: technique,
        pattern: pattern,
        eliminations: const [],
        placementIndex: start.index,
        placementDigit: start.digit,
        links: links,
        chainCells: chainCells,
        chainNodes: nodes,
        isLoop: true,
        focus:
            '从 (${start.digit})${_cellCoordinate(start.index)} 出发，可以看到起点两侧都是强链。',
        explanation:
            '如果起点候选 ${start.digit} 为假，两侧的强链会沿闭环推导出矛盾。因此这个候选必须成立，${_cellCoordinate(start.index)} = ${start.digit}。',
      );
    }
    return LogicalStep(
      technique: technique,
      pattern: pattern,
      eliminations: [start],
      links: links,
      chainCells: chainCells,
      chainNodes: nodes,
      isLoop: true,
      focus:
          '从 (${start.digit})${_cellCoordinate(start.index)} 出发，可以看到起点两侧都是弱链。',
      explanation:
          '如果起点候选 ${start.digit} 成立，两侧的弱链会沿闭环推导出矛盾。因此这个候选必须为假，可从 ${_cellCoordinate(start.index)} 删除 ${start.digit}。',
    );
  }

  List<CandidateRef> _continuousLoopEliminations({
    required List<int> masks,
    required List<CandidateRef> nodes,
    required List<LogicalLink> links,
  }) {
    final loopNodes = nodes.toSet();
    final eliminations = <CandidateRef>{};
    for (final link in links) {
      if (link.strength != LogicalLinkStrength.weak) continue;
      for (var index = 0; index < SudokuBoard.cellCount; index++) {
        for (final digit in SudokuEngine.digitsInMask(masks[index])) {
          final candidate = CandidateRef(index, digit);
          if (loopNodes.contains(candidate)) continue;
          if (_areCandidatesWeaklyLinked(candidate, link.first) &&
              _areCandidatesWeaklyLinked(candidate, link.second)) {
            eliminations.add(candidate);
          }
        }
      }
    }
    final sorted = eliminations.toList()
      ..sort((first, second) => _candidateId(first) - _candidateId(second));
    return sorted;
  }

  static bool _areCandidatesWeaklyLinked(
    CandidateRef first,
    CandidateRef second,
  ) {
    if (first == second) return false;
    if (first.index == second.index) return first.digit != second.digit;
    return first.digit == second.digit && _arePeers(first.index, second.index);
  }

  LogicalStep? _findAIC(
    List<int> masks, {
    bool type2 = false,
    int maxLinks = 11,
    int maxStates = 100000,
  }) {
    final graph = _buildAICGraph(masks);
    final queue = <_AICState>[];
    final visited = <(int, int, LogicalLinkStrength)>{};
    final starts = graph.entries
        .where(
          (entry) => entry.value.any(
            (edge) => edge.strength == LogicalLinkStrength.strong,
          ),
        )
        .map((entry) => entry.key)
        .toList();

    for (final start in starts) {
      queue.add(
        _AICState(
          nodes: [start],
          links: const [],
          nextStrength: LogicalLinkStrength.strong,
        ),
      );
      visited.add((
        _candidateId(start),
        _candidateId(start),
        LogicalLinkStrength.strong,
      ));
    }

    var cursor = 0;
    var examinedStates = 0;
    while (cursor < queue.length && examinedStates < maxStates) {
      final state = queue[cursor++];
      examinedStates++;
      final start = state.nodes.first;
      final current = state.nodes.last;
      for (final edge in graph[current] ?? const <_AICEdge>[]) {
        if (edge.strength != state.nextStrength ||
            state.nodes.contains(edge.to)) {
          continue;
        }
        final nextStrength = edge.strength == LogicalLinkStrength.strong
            ? LogicalLinkStrength.weak
            : LogicalLinkStrength.strong;
        final visitKey = (
          _candidateId(start),
          _candidateId(edge.to),
          nextStrength,
        );
        if (!visited.add(visitKey)) continue;

        final nodes = [...state.nodes, edge.to];
        final links = [
          ...state.links,
          LogicalLink(
            first: current,
            second: edge.to,
            strength: edge.strength,
            reason: edge.reason,
          ),
        ];

        if (edge.strength == LogicalLinkStrength.strong && links.length >= 5) {
          final eliminations = type2
              ? _aicType2Eliminations(masks: masks, first: start, last: edge.to)
              : start.digit == edge.to.digit && start.index != edge.to.index
              ? _commonPeerEliminations(
                  masks: masks,
                  digit: start.digit,
                  first: start.index,
                  second: edge.to.index,
                  excludedIndices: {start.index, edge.to.index},
                )
              : const <CandidateRef>[];
          if (eliminations.isNotEmpty) {
            return type2
                ? _aicType2Step(
                    nodes: nodes,
                    links: links,
                    eliminations: eliminations,
                  )
                : _aicStep(
                    nodes: nodes,
                    links: links,
                    eliminations: eliminations,
                  );
          }
        }

        if (links.length < maxLinks) {
          queue.add(
            _AICState(nodes: nodes, links: links, nextStrength: nextStrength),
          );
        }
      }
    }
    return null;
  }

  List<CandidateRef> _aicType2Eliminations({
    required List<int> masks,
    required CandidateRef first,
    required CandidateRef last,
  }) {
    if (first.digit == last.digit || !_arePeers(first.index, last.index)) {
      return const [];
    }
    return [
      if ((masks[first.index] & SudokuEngine.bitFor(last.digit)) != 0)
        CandidateRef(first.index, last.digit),
      if ((masks[last.index] & SudokuEngine.bitFor(first.digit)) != 0)
        CandidateRef(last.index, first.digit),
    ];
  }

  Map<CandidateRef, List<_AICEdge>> _buildAICGraph(List<int> masks) {
    final rawEdges = <(int, int, LogicalLinkStrength), _AICUndirectedEdge>{};

    void addEdge(
      CandidateRef first,
      CandidateRef second,
      LogicalLinkStrength strength,
      String reason,
    ) {
      final firstId = _candidateId(first);
      final secondId = _candidateId(second);
      final low = firstId < secondId ? firstId : secondId;
      final high = firstId < secondId ? secondId : firstId;
      rawEdges.putIfAbsent(
        (low, high, strength),
        () => _AICUndirectedEdge(
          first: first,
          second: second,
          strength: strength,
          reason: reason,
        ),
      );
    }

    for (var index = 0; index < SudokuBoard.cellCount; index++) {
      final digits = SudokuEngine.digitsInMask(masks[index]);
      for (final pair in _combinations(digits, 2)) {
        final first = CandidateRef(index, pair[0]);
        final second = CandidateRef(index, pair[1]);
        addEdge(
          first,
          second,
          LogicalLinkStrength.weak,
          '${_cellCoordinate(index)} 同格候选不能同时成立',
        );
        if (digits.length == 2) {
          addEdge(
            first,
            second,
            LogicalLinkStrength.strong,
            '${_cellCoordinate(index)} 是双值格',
          );
        }
      }
    }

    for (final unit in _units) {
      for (var digit = 1; digit <= 9; digit++) {
        final bit = SudokuEngine.bitFor(digit);
        final positions = [
          for (final index in unit.cells)
            if ((masks[index] & bit) != 0) index,
        ];
        for (final pair in _combinations(positions, 2)) {
          addEdge(
            CandidateRef(pair[0], digit),
            CandidateRef(pair[1], digit),
            LogicalLinkStrength.weak,
            '${unit.label}内的候选 $digit 不能同时成立',
          );
        }
        if (positions.length == 2) {
          addEdge(
            CandidateRef(positions[0], digit),
            CandidateRef(positions[1], digit),
            LogicalLinkStrength.strong,
            '${unit.label}只有这两个候选 $digit',
          );
        }
      }
    }

    final graph = <CandidateRef, List<_AICEdge>>{};
    for (final raw in rawEdges.values) {
      graph
          .putIfAbsent(raw.first, () => <_AICEdge>[])
          .add(
            _AICEdge(
              to: raw.second,
              strength: raw.strength,
              reason: raw.reason,
            ),
          );
      graph
          .putIfAbsent(raw.second, () => <_AICEdge>[])
          .add(
            _AICEdge(to: raw.first, strength: raw.strength, reason: raw.reason),
          );
    }
    return graph;
  }

  LogicalStep _aicStep({
    required List<CandidateRef> nodes,
    required List<LogicalLink> links,
    required List<CandidateRef> eliminations,
  }) {
    final first = nodes.first;
    final last = nodes.last;
    return LogicalStep(
      technique: LogicalTechnique.aic,
      pattern: nodes.toSet().toList(),
      eliminations: eliminations,
      links: links,
      chainNodes: nodes,
      focus:
          '从候选 (${first.digit})${_cellCoordinate(first.index)} 开始，追踪一条由格、行、列或宫连接的交替链。',
      explanation:
          '这条链依次交替使用强链和弱链，并以强链结束在 (${last.digit})${_cellCoordinate(last.index)}。如果起点的 ${first.digit} 为假，链尾的 ${last.digit} 就必为真，因此两个端点至少一个成立；同时看到两端的格可以删除候选 ${first.digit}。',
    );
  }

  LogicalStep _aicType2Step({
    required List<CandidateRef> nodes,
    required List<LogicalLink> links,
    required List<CandidateRef> eliminations,
  }) {
    final first = nodes.first;
    final last = nodes.last;
    return LogicalStep(
      technique: LogicalTechnique.aicType2,
      pattern: nodes.toSet().toList(),
      eliminations: eliminations,
      links: links,
      chainNodes: nodes,
      focus:
          '从候选 (${first.digit})${_cellCoordinate(first.index)} 开始，追踪到与它互看的不同候选 (${last.digit})${_cellCoordinate(last.index)}。',
      explanation:
          '交替链以强链开始和结束：若起点 ${first.digit} 为假，终点 ${last.digit} 必为真；若起点成立，又会通过同行、同列或同宫排除终点格中的 ${first.digit}。因此 ${_cellCoordinate(first.index)} 不能取 ${last.digit}，${_cellCoordinate(last.index)} 不能取 ${first.digit}。',
    );
  }

  LogicalStep? _findGroupedAIC(
    List<int> masks, {
    bool type2 = false,
    int maxLinks = 13,
    int maxStates = 180000,
  }) {
    final graph = _buildGroupedAICGraph(masks);
    final queue = <_GroupedAICState>[];
    for (final entry in graph.entries) {
      if (entry.key.isGroup ||
          !entry.value.any(
            (edge) => edge.strength == LogicalLinkStrength.strong,
          )) {
        continue;
      }
      queue.add(
        _GroupedAICState(
          nodes: [entry.key],
          links: const [],
          nextStrength: LogicalLinkStrength.strong,
        ),
      );
    }

    var cursor = 0;
    var examinedStates = 0;
    var enqueuedStates = queue.length;
    while (cursor < queue.length && examinedStates < maxStates) {
      final state = queue[cursor++];
      examinedStates++;
      final start = state.nodes.first;
      final current = state.nodes.last;
      for (final edge in graph[current] ?? const <_GroupedAICEdge>[]) {
        if (edge.strength != state.nextStrength ||
            state.nodes.contains(edge.to) ||
            state.nodes.any((node) => node.overlaps(edge.to))) {
          continue;
        }
        final link = LogicalGroupLink(
          firstGroup: current.candidates,
          secondGroup: edge.to.candidates,
          strength: edge.strength,
          reason: edge.reason,
        );
        final nodes = [...state.nodes, edge.to];
        final links = [...state.links, link];
        final hasGroupNode = nodes.any((node) => node.isGroup);

        if (edge.strength == LogicalLinkStrength.strong &&
            links.length >= 5 &&
            !edge.to.isGroup &&
            hasGroupNode) {
          final first = start.candidates.single;
          final last = edge.to.candidates.single;
          final pattern = {for (final node in nodes) ...node.candidates};
          final eliminations = type2
              ? _aicType2Eliminations(
                  masks: masks,
                  first: first,
                  last: last,
                ).where((candidate) => !pattern.contains(candidate)).toList()
              : first.digit == last.digit && first.index != last.index
              ? _commonPeerEliminations(
                  masks: masks,
                  digit: first.digit,
                  first: first.index,
                  second: last.index,
                  excludedIndices: pattern
                      .map((candidate) => candidate.index)
                      .toSet(),
                )
              : const <CandidateRef>[];
          if (eliminations.isNotEmpty) {
            return _groupedAICStep(
              nodes: nodes,
              links: links,
              eliminations: eliminations,
              type2: type2,
            );
          }
        }

        if (links.length < maxLinks && enqueuedStates < maxStates) {
          queue.add(
            _GroupedAICState(
              nodes: nodes,
              links: links,
              nextStrength: edge.strength == LogicalLinkStrength.strong
                  ? LogicalLinkStrength.weak
                  : LogicalLinkStrength.strong,
            ),
          );
          enqueuedStates++;
        }
      }
    }
    return null;
  }

  LogicalStep _groupedAICStep({
    required List<_GroupedAICNode> nodes,
    required List<LogicalGroupLink> links,
    required List<CandidateRef> eliminations,
    required bool type2,
  }) {
    final first = nodes.first.candidates.single;
    final groupCount = nodes.where((node) => node.isGroup).length;
    return LogicalStep(
      technique: type2
          ? LogicalTechnique.groupedAicType2
          : LogicalTechnique.groupedAic,
      pattern: {for (final node in nodes) ...node.candidates}.toList(),
      eliminations: eliminations,
      groupLinks: links,
      chainCells: {
        for (final node in nodes)
          for (final candidate in node.candidates) candidate.index,
      }.toList(),
      chainGroups: [for (final node in nodes) node.candidates],
      focus:
          '从 (${first.digit})${_cellCoordinate(first.index)} 出发，沿强弱链交替追踪，其中有 $groupCount 个高亮节点由多格候选组成。',
      explanation: type2
          ? '这条 Grouped AIC 以强链开始和结束，组节点表示“其中至少一个候选成立”。链的两端是互看的不同候选，因此可删除两个端点格中与对端对应的候选。'
          : '这条 Grouped AIC 以强链开始和结束，组节点表示“其中至少一个候选成立”。两个端点至少有一个成立，同时看到两端的格可删除候选 ${first.digit}。',
    );
  }

  LogicalStep? _findGroupedNiceLoop(
    List<int> masks, {
    required bool continuous,
    int maxLinks = 14,
    int maxStates = 200000,
  }) {
    if (continuous) {
      return _findGroupedAlternatingLoop(
        masks,
        continuous: true,
        initialStrength: LogicalLinkStrength.strong,
        maxLinks: maxLinks,
        maxStates: maxStates,
      );
    }
    return _findGroupedAlternatingLoop(
          masks,
          continuous: false,
          initialStrength: LogicalLinkStrength.strong,
          maxLinks: maxLinks,
          maxStates: maxStates,
        ) ??
        _findGroupedAlternatingLoop(
          masks,
          continuous: false,
          initialStrength: LogicalLinkStrength.weak,
          maxLinks: maxLinks,
          maxStates: maxStates,
        );
  }

  LogicalStep? _findGroupedAlternatingLoop(
    List<int> masks, {
    required bool continuous,
    required LogicalLinkStrength initialStrength,
    required int maxLinks,
    required int maxStates,
  }) {
    final graph = _buildGroupedAICGraph(masks);
    final queue = <_GroupedAICState>[];
    for (final entry in graph.entries) {
      if (!entry.key.isGroup &&
          entry.value.any((edge) => edge.strength == initialStrength)) {
        queue.add(
          _GroupedAICState(
            nodes: [entry.key],
            links: const [],
            nextStrength: initialStrength,
          ),
        );
      }
    }

    var cursor = 0;
    var examinedStates = 0;
    var enqueuedStates = queue.length;
    while (cursor < queue.length && examinedStates < maxStates) {
      final state = queue[cursor++];
      examinedStates++;
      final start = state.nodes.first;
      final current = state.nodes.last;
      for (final edge in graph[current] ?? const <_GroupedAICEdge>[]) {
        if (edge.strength != state.nextStrength) continue;
        final link = LogicalGroupLink(
          firstGroup: current.candidates,
          secondGroup: edge.to.candidates,
          strength: edge.strength,
          reason: edge.reason,
        );

        if (edge.to == start) {
          final linkCount = state.links.length + 1;
          if (linkCount < 4 ||
              !state.nodes.any((node) => node.isGroup) ||
              state.links.isEmpty) {
            continue;
          }
          final closesContinuously =
              edge.strength != state.links.first.strength;
          if (continuous != closesContinuously ||
              (!continuous && linkCount < 5)) {
            continue;
          }
          final links = [...state.links, link];
          final step = _groupedLoopStep(
            masks: masks,
            nodes: state.nodes,
            links: links,
            continuous: continuous,
          );
          if (step != null) return step;
          continue;
        }

        if (state.nodes.contains(edge.to) ||
            state.nodes.any((node) => node.overlaps(edge.to)) ||
            state.links.length + 1 >= maxLinks ||
            enqueuedStates >= maxStates) {
          continue;
        }
        queue.add(
          _GroupedAICState(
            nodes: [...state.nodes, edge.to],
            links: [...state.links, link],
            nextStrength: edge.strength == LogicalLinkStrength.strong
                ? LogicalLinkStrength.weak
                : LogicalLinkStrength.strong,
          ),
        );
        enqueuedStates++;
      }
    }
    return null;
  }

  LogicalStep? _groupedLoopStep({
    required List<int> masks,
    required List<_GroupedAICNode> nodes,
    required List<LogicalGroupLink> links,
    required bool continuous,
  }) {
    final start = nodes.first.candidates.single;
    final pattern = {for (final node in nodes) ...node.candidates};
    final chainCells = {for (final candidate in pattern) candidate.index}
        .toList();
    final chainGroups = [for (final node in nodes) node.candidates];
    final groupCount = nodes.where((node) => node.isGroup).length;

    if (continuous) {
      final eliminations = _groupedContinuousLoopEliminations(
        masks: masks,
        nodes: nodes,
        links: links,
      );
      if (eliminations.isEmpty) return null;
      return LogicalStep(
        technique: LogicalTechnique.groupedContinuousNiceLoop,
        pattern: pattern.toList(),
        eliminations: eliminations,
        groupLinks: links,
        chainCells: chainCells,
        chainGroups: chainGroups,
        isLoop: true,
        focus:
            '从 (${start.digit})${_cellCoordinate(start.index)} 出发，经过 $groupCount 个组节点后回到起点，检查闭环上的每条弱链。',
        explanation:
            '这是强弱链完整交替的组节点连续闭环。每条弱链的两个节点至少有一端成立，所以同时与两端所有候选冲突的其他候选可以删除。',
      );
    }

    if (links.first.strength == LogicalLinkStrength.strong) {
      return LogicalStep(
        technique: LogicalTechnique.groupedDiscontinuousNiceLoop,
        pattern: pattern.toList(),
        eliminations: const [],
        placementIndex: start.index,
        placementDigit: start.digit,
        groupLinks: links,
        chainCells: chainCells,
        chainGroups: chainGroups,
        isLoop: true,
        focus:
            '从 (${start.digit})${_cellCoordinate(start.index)} 出发，经过 $groupCount 个组节点后，起点两侧同为强链。',
        explanation:
            '起点候选如果为假，两侧强链经过组节点推导后会产生矛盾，因此 ${_cellCoordinate(start.index)} = ${start.digit}。',
      );
    }
    return LogicalStep(
      technique: LogicalTechnique.groupedDiscontinuousNiceLoop,
      pattern: pattern.toList(),
      eliminations: [start],
      groupLinks: links,
      chainCells: chainCells,
      chainGroups: chainGroups,
      isLoop: true,
      focus:
          '从 (${start.digit})${_cellCoordinate(start.index)} 出发，经过 $groupCount 个组节点后，起点两侧同为弱链。',
      explanation:
          '起点候选如果成立，两侧弱链经过组节点推导后会产生矛盾，因此可从 ${_cellCoordinate(start.index)} 删除 ${start.digit}。',
    );
  }

  List<CandidateRef> _groupedContinuousLoopEliminations({
    required List<int> masks,
    required List<_GroupedAICNode> nodes,
    required List<LogicalGroupLink> links,
  }) {
    final pattern = {for (final node in nodes) ...node.candidates};
    final eliminations = <CandidateRef>{};
    for (final link in links) {
      if (link.strength != LogicalLinkStrength.weak) continue;
      final first = _GroupedAICNode(link.firstGroup);
      final second = _GroupedAICNode(link.secondGroup);
      for (var index = 0; index < SudokuBoard.cellCount; index++) {
        for (final digit in SudokuEngine.digitsInMask(masks[index])) {
          final candidate = CandidateRef(index, digit);
          if (pattern.contains(candidate)) continue;
          if (_candidateWeaklyLinkedToGroup(candidate, first) &&
              _candidateWeaklyLinkedToGroup(candidate, second)) {
            eliminations.add(candidate);
          }
        }
      }
    }
    final sorted = eliminations.toList()
      ..sort((first, second) => _candidateId(first) - _candidateId(second));
    return sorted;
  }

  Map<_GroupedAICNode, List<_GroupedAICEdge>> _buildGroupedAICGraph(
    List<int> masks,
  ) {
    final nodesByKey = <String, _GroupedAICNode>{};

    _GroupedAICNode addNode(Iterable<CandidateRef> candidates) {
      final node = _GroupedAICNode(candidates);
      return nodesByKey.putIfAbsent(node.key, () => node);
    }

    for (var index = 0; index < SudokuBoard.cellCount; index++) {
      for (final digit in SudokuEngine.digitsInMask(masks[index])) {
        addNode([CandidateRef(index, digit)]);
      }
    }

    for (var digit = 1; digit <= 9; digit++) {
      final bit = SudokuEngine.bitFor(digit);
      for (final box in SudokuEngine.boxes) {
        for (final line in [...SudokuEngine.rows, ...SudokuEngine.columns]) {
          final positions = [
            for (final index in box)
              if (line.contains(index) && (masks[index] & bit) != 0) index,
          ];
          if (positions.length >= 2) {
            addNode([
              for (final index in positions) CandidateRef(index, digit),
            ]);
          }
        }
      }
    }

    final rawEdges =
        <(String, String, LogicalLinkStrength), _GroupedAICUndirectedEdge>{};
    void addEdge(
      _GroupedAICNode first,
      _GroupedAICNode second,
      LogicalLinkStrength strength,
      String reason,
    ) {
      if (first == second || first.overlaps(second)) return;
      final low = first.key.compareTo(second.key) < 0 ? first : second;
      final high = identical(low, first) ? second : first;
      rawEdges.putIfAbsent(
        (low.key, high.key, strength),
        () => _GroupedAICUndirectedEdge(
          first: low,
          second: high,
          strength: strength,
          reason: reason,
        ),
      );
    }

    final nodes = nodesByKey.values.toList();
    for (var firstIndex = 0; firstIndex < nodes.length; firstIndex++) {
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < nodes.length;
        secondIndex++
      ) {
        final first = nodes[firstIndex];
        final second = nodes[secondIndex];
        if (_groupNodesWeaklyLinked(first, second)) {
          addEdge(first, second, LogicalLinkStrength.weak, '两个节点中的候选不能同时成立');
        }
      }
    }

    for (var index = 0; index < SudokuBoard.cellCount; index++) {
      final digits = SudokuEngine.digitsInMask(masks[index]);
      if (digits.length != 2) continue;
      addEdge(
        addNode([CandidateRef(index, digits[0])]),
        addNode([CandidateRef(index, digits[1])]),
        LogicalLinkStrength.strong,
        '${_cellCoordinate(index)} 是双值格',
      );
    }

    final nodesByDigit = <int, List<_GroupedAICNode>>{};
    for (final node in nodesByKey.values) {
      nodesByDigit.putIfAbsent(node.digit, () => []).add(node);
    }
    for (final unit in _units) {
      final unitIndices = unit.cells.toSet();
      for (var digit = 1; digit <= 9; digit++) {
        final bit = SudokuEngine.bitFor(digit);
        final positions = {
          for (final index in unit.cells)
            if ((masks[index] & bit) != 0) CandidateRef(index, digit),
        };
        if (positions.length < 2) continue;
        final eligible = [
          for (final node in nodesByDigit[digit] ?? const <_GroupedAICNode>[])
            if (node.candidates.every(
              (candidate) => unitIndices.contains(candidate.index),
            ))
              node,
        ];
        for (final pair in _combinations(eligible, 2)) {
          final first = pair[0];
          final second = pair[1];
          if (first.overlaps(second)) continue;
          if ({...first.candidates, ...second.candidates}.length ==
                  positions.length &&
              positions.containsAll(first.candidates) &&
              positions.containsAll(second.candidates)) {
            addEdge(
              first,
              second,
              LogicalLinkStrength.strong,
              '${unit.label}的候选 $digit 只剩这两个节点',
            );
          }
        }
      }
    }

    final graph = <_GroupedAICNode, List<_GroupedAICEdge>>{};
    for (final raw in rawEdges.values) {
      graph
          .putIfAbsent(raw.first, () => [])
          .add(
            _GroupedAICEdge(
              to: raw.second,
              strength: raw.strength,
              reason: raw.reason,
            ),
          );
      graph
          .putIfAbsent(raw.second, () => [])
          .add(
            _GroupedAICEdge(
              to: raw.first,
              strength: raw.strength,
              reason: raw.reason,
            ),
          );
    }
    return graph;
  }

  static bool _groupNodesWeaklyLinked(
    _GroupedAICNode first,
    _GroupedAICNode second,
  ) =>
      !first.overlaps(second) &&
      first.candidates.every(
        (firstCandidate) => second.candidates.every(
          (secondCandidate) =>
              _areCandidatesWeaklyLinked(firstCandidate, secondCandidate),
        ),
      );

  static bool _candidateWeaklyLinkedToGroup(
    CandidateRef candidate,
    _GroupedAICNode group,
  ) =>
      !group.candidates.contains(candidate) &&
      group.candidates.every(
        (member) => _areCandidatesWeaklyLinked(candidate, member),
      );

  LogicalStep? _findAlsXZ(
    List<int> masks, {
    required bool doublyLinked,
    int maxCellsPerAls = 4,
  }) {
    final alsList = _enumerateAls(masks, maxCells: maxCellsPerAls);
    LogicalStep? bestStep;
    var bestEliminationCount = 0;
    var bestCellCount = SudokuBoard.cellCount + 1;
    for (var firstIndex = 0; firstIndex < alsList.length; firstIndex++) {
      final first = alsList[firstIndex];
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < alsList.length;
        secondIndex++
      ) {
        final second = alsList[secondIndex];
        if (first.cells.any(second.cells.contains)) continue;
        final sharedMask = first.mask & second.mask;
        if (SudokuEngine.countBits(sharedMask) == 0) continue;

        final rccDigits = <int>[];
        for (final digit in SudokuEngine.digitsInMask(sharedMask)) {
          final firstInstances = first.instancesOf(digit, masks);
          final secondInstances = second.instancesOf(digit, masks);
          if (firstInstances.every(
            (firstCell) => secondInstances.every(
              (secondCell) => _arePeers(firstCell, secondCell),
            ),
          )) {
            rccDigits.add(digit);
          }
        }
        if (doublyLinked ? rccDigits.length != 2 : rccDigits.length != 1) {
          continue;
        }

        final eliminations = doublyLinked
            ? _doublyLinkedAlsEliminations(
                masks: masks,
                first: first,
                second: second,
                rccDigits: rccDigits,
              )
            : _singlyLinkedAlsEliminations(
                masks: masks,
                first: first,
                second: second,
                rccDigit: rccDigits.single,
              );
        if (eliminations.isEmpty) continue;
        final cellCount = first.cells.length + second.cells.length;
        if (eliminations.length < bestEliminationCount ||
            (eliminations.length == bestEliminationCount &&
                cellCount >= bestCellCount)) {
          continue;
        }
        bestEliminationCount = eliminations.length;
        bestCellCount = cellCount;
        bestStep = _alsXZStep(
          masks: masks,
          first: first,
          second: second,
          rccDigits: rccDigits,
          eliminations: eliminations,
          doublyLinked: doublyLinked,
        );
      }
    }
    return bestStep;
  }

  List<CandidateRef> _singlyLinkedAlsEliminations({
    required List<int> masks,
    required _AlmostLockedSet first,
    required _AlmostLockedSet second,
    required int rccDigit,
  }) {
    final eliminations = <CandidateRef>{};
    final commonZMask =
        first.mask & second.mask & ~SudokuEngine.bitFor(rccDigit);
    final alsCells = {...first.cells, ...second.cells};
    for (final digit in SudokuEngine.digitsInMask(commonZMask)) {
      final instances = {
        ...first.instancesOf(digit, masks),
        ...second.instancesOf(digit, masks),
      };
      final bit = SudokuEngine.bitFor(digit);
      for (var index = 0; index < SudokuBoard.cellCount; index++) {
        if (alsCells.contains(index) || (masks[index] & bit) == 0) continue;
        if (instances.every((instance) => _arePeers(index, instance))) {
          eliminations.add(CandidateRef(index, digit));
        }
      }
    }
    return _sortedCandidates(eliminations);
  }

  List<CandidateRef> _doublyLinkedAlsEliminations({
    required List<int> masks,
    required _AlmostLockedSet first,
    required _AlmostLockedSet second,
    required List<int> rccDigits,
  }) {
    final eliminations = <CandidateRef>{};
    final allAlsCells = {...first.cells, ...second.cells};
    var rccMask = 0;
    for (final digit in rccDigits) {
      rccMask |= SudokuEngine.bitFor(digit);
      final instances = {
        ...first.instancesOf(digit, masks),
        ...second.instancesOf(digit, masks),
      };
      final bit = SudokuEngine.bitFor(digit);
      for (var index = 0; index < SudokuBoard.cellCount; index++) {
        if (allAlsCells.contains(index) || (masks[index] & bit) == 0) continue;
        if (instances.every((instance) => _arePeers(index, instance))) {
          eliminations.add(CandidateRef(index, digit));
        }
      }
    }

    for (final als in [first, second]) {
      final nonRccMask = als.mask & ~rccMask;
      for (final digit in SudokuEngine.digitsInMask(nonRccMask)) {
        final instances = als.instancesOf(digit, masks);
        final bit = SudokuEngine.bitFor(digit);
        for (var index = 0; index < SudokuBoard.cellCount; index++) {
          if (als.cells.contains(index) || (masks[index] & bit) == 0) continue;
          if (instances.every((instance) => _arePeers(index, instance))) {
            eliminations.add(CandidateRef(index, digit));
          }
        }
      }
    }
    return _sortedCandidates(eliminations);
  }

  LogicalStep _alsXZStep({
    required List<int> masks,
    required _AlmostLockedSet first,
    required _AlmostLockedSet second,
    required List<int> rccDigits,
    required List<CandidateRef> eliminations,
    required bool doublyLinked,
  }) {
    final firstCandidates = [
      for (final cell in first.cells)
        for (final digit in SudokuEngine.digitsInMask(masks[cell]))
          CandidateRef(cell, digit),
    ];
    final secondCandidates = [
      for (final cell in second.cells)
        for (final digit in SudokuEngine.digitsInMask(masks[cell]))
          CandidateRef(cell, digit),
    ];
    final firstLabel = first.cells.map(_cellCoordinate).join('、');
    final secondLabel = second.cells.map(_cellCoordinate).join('、');
    final firstDigits = SudokuEngine.digitsInMask(first.mask).join('');
    final secondDigits = SudokuEngine.digitsInMask(second.mask).join('');
    final rccLabel = rccDigits.join('、');
    return LogicalStep(
      technique: doublyLinked
          ? LogicalTechnique.doublyLinkedAlsXZ
          : LogicalTechnique.alsXZ,
      pattern: {...firstCandidates, ...secondCandidates}.toList(),
      eliminations: eliminations,
      chainCells: [...first.cells, ...second.cells],
      candidateColors: {
        for (final candidate in firstCandidates) candidate: 0,
        for (final candidate in secondCandidates) candidate: 1,
      },
      focus:
          '对比 ALS A（$firstLabel，候选 {$firstDigits}）与 ALS B（$secondLabel，候选 {$secondDigits}）。',
      explanation: doublyLinked
          ? '两个 ALS 都是 N 格 N+1 个候选，并由两个受限共同候选 $rccLabel 双重连接。两个 RCC 必须分别锁定在两个 ALS 中，因此 RCC 和其他已锁定候选都能产生高亮删数。'
          : '两个 ALS 都是 N 格 N+1 个候选，受限共同候选 X=$rccLabel 不能同时出现在两组中。因此至少一个 ALS 会锁定，两组共有的其他 Z 候选至少有一处成立，同时看到它们所有可能位置的格可删除 Z。',
    );
  }

  List<_AlmostLockedSet> _enumerateAls(
    List<int> masks, {
    required int maxCells,
  }) {
    final byKey = <String, _AlmostLockedSet>{};
    for (final unit in _units) {
      final cells = [
        for (final index in unit.cells)
          if (SudokuEngine.countBits(masks[index]) >= 2) index,
      ];
      final limit = cells.length < maxCells ? cells.length : maxCells;
      for (var size = 1; size <= limit; size++) {
        for (final selected in _combinations(cells, size)) {
          var unionMask = 0;
          for (final cell in selected) {
            unionMask |= masks[cell];
          }
          if (SudokuEngine.countBits(unionMask) != size + 1) continue;
          final als = _AlmostLockedSet(selected, unionMask);
          byKey.putIfAbsent(als.key, () => als);
        }
      }
    }
    return byKey.values.toList();
  }

  static List<CandidateRef> _sortedCandidates(
    Iterable<CandidateRef> candidates,
  ) {
    final sorted = candidates.toList()
      ..sort((first, second) => _candidateId(first) - _candidateId(second));
    return sorted;
  }

  static int _candidateId(CandidateRef candidate) =>
      candidate.index * 9 + candidate.digit - 1;

  static int _boxOf(int index) => (index ~/ 9) ~/ 3 * 3 + (index % 9) ~/ 3;

  static bool _arePeers(int first, int second) {
    if (first == second) return false;
    return first ~/ 9 == second ~/ 9 ||
        first % 9 == second % 9 ||
        _boxOf(first) == _boxOf(second);
  }

  static String _cellLabel(int index) =>
      '第 ${index ~/ 9 + 1} 行 ${index % 9 + 1} 列';

  static String _cellCoordinate(int index) =>
      'r${index ~/ 9 + 1}c${index % 9 + 1}';

  static String _chineseCount(int count) => switch (count) {
    2 => '两',
    3 => '三',
    4 => '四',
    _ => '$count',
  };

  static List<List<T>> _combinations<T>(List<T> source, int size) {
    final result = <List<T>>[];

    void choose(int start, List<T> selected) {
      if (selected.length == size) {
        result.add(List<T>.of(selected));
        return;
      }
      final remaining = size - selected.length;
      for (var index = start; index <= source.length - remaining; index++) {
        selected.add(source[index]);
        choose(index + 1, selected);
        selected.removeLast();
      }
    }

    choose(0, <T>[]);
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

class _XYChainState {
  const _XYChainState({
    required this.path,
    required this.startDigit,
    required this.outgoingDigit,
  });

  final List<int> path;
  final int startDigit;
  final int outgoingDigit;
}

class _AICEdge {
  const _AICEdge({
    required this.to,
    required this.strength,
    required this.reason,
  });

  final CandidateRef to;
  final LogicalLinkStrength strength;
  final String reason;
}

class _AICUndirectedEdge {
  const _AICUndirectedEdge({
    required this.first,
    required this.second,
    required this.strength,
    required this.reason,
  });

  final CandidateRef first;
  final CandidateRef second;
  final LogicalLinkStrength strength;
  final String reason;
}

class _AICState {
  const _AICState({
    required this.nodes,
    required this.links,
    required this.nextStrength,
  });

  final List<CandidateRef> nodes;
  final List<LogicalLink> links;
  final LogicalLinkStrength nextStrength;
}

enum _LoopMode { xCycle, discontinuousNiceLoop, continuousNiceLoop }

class _GroupedAICNode {
  factory _GroupedAICNode(Iterable<CandidateRef> source) {
    final candidates = source.toSet().toList()
      ..sort(
        (first, second) =>
            (first.index * 9 + first.digit) - (second.index * 9 + second.digit),
      );
    final key = candidates
        .map((candidate) => '${candidate.index}:${candidate.digit}')
        .join(',');
    return _GroupedAICNode._(List.unmodifiable(candidates), key);
  }

  const _GroupedAICNode._(this.candidates, this.key);

  final List<CandidateRef> candidates;
  final String key;

  int get digit => candidates.first.digit;
  bool get isGroup => candidates.length > 1;

  bool overlaps(_GroupedAICNode other) =>
      candidates.any(other.candidates.contains);

  @override
  bool operator ==(Object other) =>
      other is _GroupedAICNode && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

class _GroupedAICEdge {
  const _GroupedAICEdge({
    required this.to,
    required this.strength,
    required this.reason,
  });

  final _GroupedAICNode to;
  final LogicalLinkStrength strength;
  final String reason;
}

class _GroupedAICUndirectedEdge {
  const _GroupedAICUndirectedEdge({
    required this.first,
    required this.second,
    required this.strength,
    required this.reason,
  });

  final _GroupedAICNode first;
  final _GroupedAICNode second;
  final LogicalLinkStrength strength;
  final String reason;
}

class _GroupedAICState {
  const _GroupedAICState({
    required this.nodes,
    required this.links,
    required this.nextStrength,
  });

  final List<_GroupedAICNode> nodes;
  final List<LogicalGroupLink> links;
  final LogicalLinkStrength nextStrength;
}

class _AlmostLockedSet {
  _AlmostLockedSet(Iterable<int> source, this.mask)
    : cells = (source.toList()..sort()),
      key = (source.toList()..sort()).join(',');

  final List<int> cells;
  final int mask;
  final String key;

  List<int> instancesOf(int digit, List<int> masks) {
    final bit = SudokuEngine.bitFor(digit);
    return [
      for (final cell in cells)
        if ((masks[cell] & bit) != 0) cell,
    ];
  }
}
