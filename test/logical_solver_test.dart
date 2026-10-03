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
}

({List<int> values, List<int> excludedMasks}) _syntheticChainState() {
  const allowedNines = {0, 4, 14, 36, 41};
  final excludedMasks = List<int>.generate(
    81,
    (index) => allowedNines.contains(index) ? 0 : SudokuEngine.bitFor(9),
  );
  return (values: List<int>.filled(81, 0), excludedMasks: excludedMasks);
}
