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
}

({List<int> values, List<int> excludedMasks}) _syntheticChainState() {
  const allowedNines = {0, 4, 14, 36, 41};
  final excludedMasks = List<int>.generate(
    81,
    (index) => allowedNines.contains(index) ? 0 : SudokuEngine.bitFor(9),
  );
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
