// ignore_for_file: avoid_print

import 'package:sudoku_helper/src/logic/logical_solver.dart';
import 'package:sudoku_helper/src/logic/puzzle_generator.dart';

void main(List<String> arguments) {
  final seed = arguments.isEmpty ? 20260929 : int.parse(arguments.first);
  const generator = PuzzleGenerator();
  const logicalSolver = LogicalSolver();
  for (final difficulty in PuzzleDifficulty.values) {
    final stopwatch = Stopwatch()..start();
    final result = generator.generate(
      difficulty,
      seed: seed + difficulty.index,
    );
    stopwatch.stop();
    final techniques = logicalSolver
        .solve(result.puzzle.values)
        .steps
        .map((step) => step.technique.label)
        .toSet()
        .join('、');
    print(
      '${difficulty.label}: actual=${result.difficulty.label}, '
      'clues=${result.clueCount}, steps=${result.logicalStepCount}, '
      'seed=${result.seed}, ms=${stopwatch.elapsedMilliseconds}, '
      'techniques=$techniques',
    );
    print(result.puzzle.encode());
  }
}
