// ignore_for_file: avoid_print

import 'package:sudoku_helper/src/logic/logical_solver.dart';
import 'package:sudoku_helper/src/logic/puzzle_generator.dart';

void main(List<String> arguments) {
  final seed = arguments.isEmpty ? 20260929 : int.parse(arguments.first);
  const generator = PuzzleGenerator();
  for (final difficulty in PuzzleDifficulty.values) {
    final stopwatch = Stopwatch()..start();
    final result = generator.generate(
      difficulty,
      seed: seed + difficulty.index,
    );
    stopwatch.stop();
    print(
      '${difficulty.label}: actual=${result.difficulty.label}, '
      'clues=${result.clueCount}, steps=${result.logicalStepCount}, '
      'seed=${result.seed}, ms=${stopwatch.elapsedMilliseconds}',
    );
    print(result.puzzle.encode());
  }
}
