import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_helper/src/logic/logical_solver.dart';
import 'package:sudoku_helper/src/logic/puzzle_generator.dart';
import 'package:sudoku_helper/src/logic/sudoku_engine.dart';
import 'package:sudoku_helper/src/model/sudoku_board.dart';

const easyBySingles =
    '530070000'
    '600195000'
    '098000060'
    '800060003'
    '400803001'
    '700020006'
    '060000280'
    '000419005'
    '000080079';

const realXYChainPuzzle =
    '700060009'
    '000900500'
    '000050040'
    '090200006'
    '075000300'
    '004003020'
    '060010000'
    '007004000'
    '300020064';

const realAICPuzzle =
    '080050300'
    '070028000'
    '900003006'
    '050000020'
    '700000009'
    '020000030'
    '300200054'
    '000130000'
    '008009010';

void main() {
  const logicalSolver = LogicalSolver();
  const engine = SudokuEngine();
  const generator = PuzzleGenerator();

  test('logical solver completes an entry puzzle using only singles', () {
    final result = logicalSolver.solve(SudokuBoard.parse(easyBySingles).values);

    expect(result.solved, isTrue);
    expect(result.hardestDifficulty, PuzzleDifficulty.beginner);
    expect(result.steps, hasLength(51));
    expect(
      result.steps.every(
        (step) =>
            step.technique == LogicalTechnique.nakedSingle ||
            step.technique == LogicalTechnique.hiddenSingle,
      ),
      isTrue,
    );
  });

  test('generator returns unique puzzles at all requested ratings', () {
    for (final difficulty in PuzzleDifficulty.values) {
      final generated = generator.generate(
        difficulty,
        seed: 20260929 + difficulty.index,
      );
      final uniqueness = engine.analyzeSolutions(generated.puzzle.values);
      final logicalResult = logicalSolver.solve(generated.puzzle.values);

      expect(uniqueness.hasUniqueSolution, isTrue, reason: difficulty.label);
      expect(logicalResult.solved, isTrue, reason: difficulty.label);
      expect(
        logicalResult.hardestDifficulty,
        difficulty,
        reason: difficulty.label,
      );
    }
  });

  test('hard puzzle includes an explainable advanced structure', () {
    final generated = generator.generate(PuzzleDifficulty.hard, seed: 20260932);
    final result = logicalSolver.solve(generated.puzzle.values);

    expect(result.solved, isTrue);
    expect(
      result.steps.any((step) => step.difficulty == PuzzleDifficulty.hard),
      isTrue,
    );
  });

  test('naked quad removes its four digits from the rest of a unit', () {
    final state = _nakedQuadState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.nakedQuad,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.nakedQuad);
    expect(step.eliminations, contains(const CandidateRef(4, 1)));
  });

  test('hidden quad removes other candidates from its four cells', () {
    final state = _hiddenQuadState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.hiddenQuad,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.hiddenQuad);
    expect(step.eliminations, contains(const CandidateRef(0, 5)));
  });

  test('Swordfish uses three base and cover lines', () {
    final state = _fishState(
      digit: 9,
      pattern: const {
        0: {0, 3},
        3: {3, 6},
        6: {0, 6},
      },
      target: 9,
    );
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.swordfish,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.swordfish);
    expect(step.pattern.map((candidate) => candidate.index).toSet(), {
      0,
      3,
      30,
      33,
      54,
      60,
    });
    expect(step.eliminations, contains(const CandidateRef(9, 9)));
  });

  test('Jellyfish uses four base and cover lines', () {
    final state = _fishState(
      digit: 8,
      pattern: const {
        0: {0, 2},
        2: {2, 4},
        4: {4, 6},
        6: {0, 6},
      },
      target: 9,
    );
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.jellyfish,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.jellyfish);
    expect(step.pattern, hasLength(8));
    expect(step.eliminations, contains(const CandidateRef(9, 8)));
  });

  test('Finned X-Wing keeps only eliminations inside the fin box', () {
    final state = _finnedXWingState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.finnedXWing,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.finnedXWing);
    expect(step.eliminations, contains(const CandidateRef(31, 9)));
    expect(step.eliminations.every((item) => item.index == 31), isTrue);
  });

  test('unique rectangle type 1 removes the deadly pair from one corner', () {
    final state = _uniqueRectangleState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.uniqueRectangleType1,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.uniqueRectangleType1);
    expect(step.eliminations, {
      const CandidateRef(28, 1),
      const CandidateRef(28, 2),
    });
  });

  test('BUG+1 places the only additional candidate', () {
    final state = _bugPlusOneState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.bugPlusOne,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.bugPlusOne);
    expect(step.placementIndex, 0);
    expect(step.placementDigit, 3);
  });

  test('XYZ-Wing eliminates the shared candidate seen by all three cells', () {
    final state = _xyzWingState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.xyzWing,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.xyzWing);
    expect(step.pattern.map((candidate) => candidate.index).toSet(), {
      12,
      21,
      24,
    });
    expect(step.eliminations, contains(const CandidateRef(22, 3)));
  });

  test('skyscraper exposes a strong-weak-strong chain', () {
    final state = _syntheticChainState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.skyscraper,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.skyscraper);
    expect(step.eliminations, contains(const CandidateRef(14, 9)));
    expect(step.links.map((link) => link.strength), [
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
    ]);
  });

  test('two-string kite exposes a strong-weak-strong chain', () {
    final state = _syntheticChainState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.twoStringKite,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.twoStringKite);
    expect(step.eliminations, contains(const CandidateRef(36, 9)));
    expect(step.links.map((link) => link.strength), [
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
    ]);
  });

  test('empty rectangle exposes grouped inference and one elimination', () {
    final state = _emptyRectangleState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.emptyRectangle,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.emptyRectangle);
    expect(step.eliminations, contains(const CandidateRef(37, 9)));
    expect(step.links, hasLength(1));
    expect(step.groupLinks.map((link) => link.strength), [
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
    ]);
  });

  test('W-Wing exposes the complete five-link chain', () {
    final state = _wWingState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.wWing,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.wWing);
    expect(step.eliminations, contains(const CandidateRef(4, 2)));
    expect(step.links.map((link) => link.strength), [
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
    ]);
  });

  test('XY-Chain finds an ordered four-cell alternating chain', () {
    final state = _xyChainState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.xyChain,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.xyChain);
    expect(step.chainCells, hasLength(4));
    expect(step.chainCells.toSet(), {0, 3, 27, 30});
    expect(step.eliminations, contains(const CandidateRef(9, 1)));
    expect(step.links.map((link) => link.strength), [
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
      LogicalLinkStrength.weak,
      LogicalLinkStrength.strong,
    ]);
  });

  test('XY-Chain is used while solving a real unique puzzle', () {
    final board = SudokuBoard.parse(realXYChainPuzzle);
    final result = logicalSolver.solve(board.values);
    final step = result.steps.firstWhere(
      (step) => step.technique == LogicalTechnique.xyChain,
    );

    expect(engine.analyzeSolutions(board.values).hasUniqueSolution, isTrue);
    expect(result.solved, isTrue);
    expect(step.chainCells.length, inInclusiveRange(4, 8));
    expect(step.links, hasLength(step.chainCells.length * 2 - 1));
    expect(step.eliminations, isNotEmpty);
  });

  test('AIC combines cell and unit links in alternating order', () {
    final state = _aicState();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.aic,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.aic);
    expect(step.eliminations, contains(const CandidateRef(6, 1)));
    expect(step.links.length, greaterThanOrEqualTo(5));
    expect(step.links.length, lessThanOrEqualTo(11));
    expect(step.links.first.strength, LogicalLinkStrength.strong);
    expect(step.links.last.strength, LogicalLinkStrength.strong);
    for (var index = 1; index < step.links.length; index++) {
      expect(step.links[index].strength, isNot(step.links[index - 1].strength));
    }
    expect(step.links.every((link) => link.reason != null), isTrue);
    expect(step.chainNodes, hasLength(step.links.length + 1));
    expect(step.chainNodes.first.digit, step.chainNodes.last.digit);
  });

  test('AIC Type 2 removes crossed endpoint candidates', () {
    final state = _aicType2State();
    final step = logicalSolver.findTechnique(
      values: state.values,
      excludedMasks: state.excludedMasks,
      technique: LogicalTechnique.aicType2,
    );

    expect(step, isNotNull);
    expect(step!.technique, LogicalTechnique.aicType2);
    expect(step.eliminations, contains(const CandidateRef(0, 4)));
    expect(step.eliminations, contains(const CandidateRef(27, 1)));
    expect(step.links.length, inInclusiveRange(5, 11));
    expect(step.chainNodes.first.digit, isNot(step.chainNodes.last.digit));
    for (var index = 1; index < step.links.length; index++) {
      expect(step.links[index].strength, isNot(step.links[index - 1].strength));
    }
  });

  test('AIC is used while solving a real unique puzzle', () {
    final board = SudokuBoard.parse(realAICPuzzle);
    final result = logicalSolver.solve(board.values);
    final step = result.steps.firstWhere(
      (step) => step.technique == LogicalTechnique.aic,
    );

    expect(engine.analyzeSolutions(board.values).hasUniqueSolution, isTrue);
    expect(result.solved, isTrue);
    expect(
      result.steps.any((step) => step.technique == LogicalTechnique.swordfish),
      isTrue,
    );
    expect(
      result.steps.any((step) => step.technique == LogicalTechnique.xyzWing),
      isTrue,
    );
    expect(step.links.length, inInclusiveRange(5, 11));
    expect(step.links.every((link) => link.reason != null), isTrue);
    expect(step.eliminations, isNotEmpty);
  });
}

({List<int> values, List<int> excludedMasks}) _syntheticChainState() {
  const allowedNines = {0, 4, 14, 36, 41};
  final excludedMasks = List<int>.generate(
    81,
    (index) => allowedNines.contains(index) ? 0 : SudokuEngine.bitFor(9),
  );
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _nakedQuadState() {
  final excludedMasks = List<int>.filled(81, 0);
  final allowedMasks = <int>[
    SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2),
    SudokuEngine.bitFor(2) | SudokuEngine.bitFor(3),
    SudokuEngine.bitFor(3) | SudokuEngine.bitFor(4),
    SudokuEngine.bitFor(1) | SudokuEngine.bitFor(4),
  ];
  for (var index = 0; index < allowedMasks.length; index++) {
    excludedMasks[index] = SudokuEngine.fullMask & ~allowedMasks[index];
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _hiddenQuadState() {
  final excludedMasks = List<int>.filled(81, 0);
  final quadMask =
      SudokuEngine.bitFor(1) |
      SudokuEngine.bitFor(2) |
      SudokuEngine.bitFor(3) |
      SudokuEngine.bitFor(4);
  for (var index = 4; index < 9; index++) {
    excludedMasks[index] |= quadMask;
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _fishState({
  required int digit,
  required Map<int, Set<int>> pattern,
  required int target,
}) {
  final bit = SudokuEngine.bitFor(digit);
  final allowed = <int>{target};
  for (final entry in pattern.entries) {
    allowed.addAll(entry.value.map((column) => entry.key * 9 + column));
  }
  final excludedMasks = List<int>.generate(
    81,
    (index) => allowed.contains(index) ? 0 : bit,
  );
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _finnedXWingState() {
  final bit = SudokuEngine.bitFor(9);
  const allowed = {0, 4, 31, 36, 39, 40};
  final excludedMasks = List<int>.generate(
    81,
    (index) => allowed.contains(index) ? 0 : bit,
  );
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _uniqueRectangleState() {
  final excludedMasks = List<int>.filled(81, 0);
  final pairMask = SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2);
  for (final index in [0, 1, 27]) {
    excludedMasks[index] = SudokuEngine.fullMask & ~pairMask;
  }
  final extraMask = pairMask | SudokuEngine.bitFor(3);
  excludedMasks[28] = SudokuEngine.fullMask & ~extraMask;
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _bugPlusOneState() {
  final excludedMasks = List<int>.generate(81, (index) {
    final row = index ~/ 9;
    final column = index % 9;
    final firstDigit = (row * 3 + row ~/ 3 + column) % 9 + 1;
    final secondDigit = firstDigit % 9 + 1;
    var allowedMask =
        SudokuEngine.bitFor(firstDigit) | SudokuEngine.bitFor(secondDigit);
    if (index == 0) allowedMask |= SudokuEngine.bitFor(3);
    return SudokuEngine.fullMask & ~allowedMask;
  });
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _xyzWingState() {
  final excludedMasks = List<int>.filled(81, 0);
  final masks = <int, int>{
    21:
        SudokuEngine.bitFor(1) |
        SudokuEngine.bitFor(2) |
        SudokuEngine.bitFor(3),
    12: SudokuEngine.bitFor(1) | SudokuEngine.bitFor(3),
    24: SudokuEngine.bitFor(2) | SudokuEngine.bitFor(3),
  };
  for (final entry in masks.entries) {
    excludedMasks[entry.key] = SudokuEngine.fullMask & ~entry.value;
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _emptyRectangleState() {
  final excludedMasks = List<int>.filled(81, 0);
  final bit = SudokuEngine.bitFor(9);
  const boxCandidates = {1, 9, 11, 19};
  for (final index in SudokuEngine.boxes[0]) {
    if (!boxCandidates.contains(index)) excludedMasks[index] |= bit;
  }
  const conjugatePair = {13, 40};
  for (final index in SudokuEngine.columns[4]) {
    if (!conjugatePair.contains(index)) excludedMasks[index] |= bit;
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _wWingState() {
  final excludedMasks = List<int>.filled(81, 0);
  final wingMask = SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2);
  excludedMasks[0] = SudokuEngine.fullMask & ~wingMask;
  excludedMasks[40] = SudokuEngine.fullMask & ~wingMask;
  final linkBit = SudokuEngine.bitFor(1);
  const conjugatePair = {18, 22};
  for (final index in SudokuEngine.rows[2]) {
    if (!conjugatePair.contains(index)) excludedMasks[index] |= linkBit;
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _xyChainState() {
  final excludedMasks = List<int>.filled(81, 0);
  final masks = <int, int>{
    0: SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2),
    3: SudokuEngine.bitFor(2) | SudokuEngine.bitFor(3),
    30: SudokuEngine.bitFor(3) | SudokuEngine.bitFor(4),
    27: SudokuEngine.bitFor(4) | SudokuEngine.bitFor(1),
  };
  for (final entry in masks.entries) {
    excludedMasks[entry.key] = SudokuEngine.fullMask & ~entry.value;
  }
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _aicState() {
  final defaultMask =
      SudokuEngine.bitFor(4) | SudokuEngine.bitFor(5) | SudokuEngine.bitFor(6);
  final allowedMasks = List<int>.filled(81, defaultMask);
  allowedMasks[0] =
      SudokuEngine.bitFor(1) | SudokuEngine.bitFor(4) | SudokuEngine.bitFor(5);
  allowedMasks[1] = allowedMasks[0];
  allowedMasks[6] = allowedMasks[0];
  allowedMasks[15] = allowedMasks[0];
  allowedMasks[54] =
      SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2) | SudokuEngine.bitFor(7);
  allowedMasks[57] =
      SudokuEngine.bitFor(2) | SudokuEngine.bitFor(3) | SudokuEngine.bitFor(8);
  allowedMasks[30] =
      SudokuEngine.bitFor(1) | SudokuEngine.bitFor(3) | SudokuEngine.bitFor(9);
  allowedMasks[33] = allowedMasks[0];
  final excludedMasks = [
    for (final mask in allowedMasks) SudokuEngine.fullMask & ~mask,
  ];
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}

({List<int> values, List<int> excludedMasks}) _aicType2State() {
  final defaultMask =
      SudokuEngine.bitFor(5) | SudokuEngine.bitFor(6) | SudokuEngine.bitFor(8);
  final allowedMasks = List<int>.filled(81, defaultMask);
  allowedMasks[0] =
      SudokuEngine.bitFor(1) | SudokuEngine.bitFor(4) | SudokuEngine.bitFor(5);
  allowedMasks[3] =
      SudokuEngine.bitFor(1) | SudokuEngine.bitFor(2) | SudokuEngine.bitFor(7);
  allowedMasks[30] =
      SudokuEngine.bitFor(2) | SudokuEngine.bitFor(3) | SudokuEngine.bitFor(8);
  allowedMasks[33] =
      SudokuEngine.bitFor(3) | SudokuEngine.bitFor(4) | SudokuEngine.bitFor(9);
  allowedMasks[27] =
      SudokuEngine.bitFor(1) | SudokuEngine.bitFor(4) | SudokuEngine.bitFor(5);
  final excludedMasks = [
    for (final mask in allowedMasks) SudokuEngine.fullMask & ~mask,
  ];
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}
