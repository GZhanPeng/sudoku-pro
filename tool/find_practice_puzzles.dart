// ignore_for_file: avoid_print

import 'package:sudoku_helper/src/logic/logical_solver.dart';
import 'package:sudoku_helper/src/logic/puzzle_generator.dart';

void main(List<String> arguments) {
  final startSeed = arguments.isEmpty ? 1 : int.parse(arguments.first);
  final limit = arguments.length < 2 ? 600 : int.parse(arguments[1]);
  const generator = PuzzleGenerator();
  const solver = LogicalSolver();
  final targets = <LogicalTechnique>{
    LogicalTechnique.xWing,
    LogicalTechnique.skyscraper,
    LogicalTechnique.twoStringKite,
    LogicalTechnique.emptyRectangle,
    LogicalTechnique.wWing,
    LogicalTechnique.xyWing,
  };
  final found = <LogicalTechnique>{};

  for (var seed = startSeed; seed < startSeed + limit; seed++) {
    for (final difficulty in [PuzzleDifficulty.medium, PuzzleDifficulty.hard]) {
      final generated = generator.generate(difficulty, seed: seed);
      final result = solver.solve(generated.puzzle.values);
      for (final target in targets.difference(found)) {
        final stepIndex = result.steps.indexWhere(
          (step) => step.technique == target,
        );
        if (stepIndex < 0) continue;
        found.add(target);
        print(
          '${target.name}|${target.label}|seed=$seed|'
          'step=$stepIndex|puzzle=${generated.puzzle.encode()}',
        );
      }
      if (found.length == targets.length) return;
    }
  }

  print('未找到：${targets.difference(found).map((item) => item.label).join('、')}');
}
