import 'dart:math';

import '../model/sudoku_board.dart';
import 'logical_solver.dart';
import 'sudoku_engine.dart';

class GeneratedPuzzle {
  const GeneratedPuzzle({
    required this.puzzle,
    required this.solution,
    required this.difficulty,
    required this.seed,
    required this.logicalStepCount,
  });

  final SudokuBoard puzzle;
  final List<int> solution;
  final PuzzleDifficulty difficulty;
  final int seed;
  final int logicalStepCount;

  int get clueCount => puzzle.filledCount;
}

class PuzzleGenerationException implements Exception {
  const PuzzleGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PuzzleGenerator {
  const PuzzleGenerator({
    this.engine = const SudokuEngine(),
    this.logicalSolver = const LogicalSolver(),
  });

  final SudokuEngine engine;
  final LogicalSolver logicalSolver;

  GeneratedPuzzle generate(
    PuzzleDifficulty requested, {
    int? seed,
    int maxAttempts = 160,
  }) {
    final generationSeed =
        seed ?? DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    final masterRandom = Random(generationSeed);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final attemptSeed = masterRandom.nextInt(0x7FFFFFFF);
      final random = Random(attemptSeed);
      final solution = _randomSolution(random);
      final targetClues = _targetClueCount(requested, random);
      final puzzleValues = _carve(
        solution,
        random,
        targetClues: targetClues,
        allowAsymmetric: requested.rank >= PuzzleDifficulty.medium.rank,
      );
      final logicalResult = logicalSolver.solve(puzzleValues);
      if (!logicalResult.solved) continue;

      final generated = GeneratedPuzzle(
        puzzle: SudokuBoard.fromValues(puzzleValues),
        solution: solution,
        difficulty: logicalResult.hardestDifficulty,
        seed: attemptSeed,
        logicalStepCount: logicalResult.steps.length,
      );
      if (generated.difficulty == requested) return generated;
    }

    final fallback = _fallback(requested, masterRandom);
    if (fallback != null) return fallback;
    throw PuzzleGenerationException('暂时没有生成可用题目，请再试一次');
  }

  GeneratedPuzzle? _fallback(PuzzleDifficulty requested, Random random) {
    final encoded = _fallbackPuzzles[requested];
    if (encoded == null) return null;
    for (var attempt = 0; attempt < 12; attempt++) {
      final puzzleValues = _transformGrid(
        SudokuBoard.parse(encoded).values,
        random,
      );
      final analysis = engine.analyzeSolutions(puzzleValues);
      final solution = analysis.firstSolution;
      if (!analysis.hasUniqueSolution || solution == null) continue;
      final logicalResult = logicalSolver.solve(puzzleValues);
      if (!logicalResult.solved ||
          logicalResult.hardestDifficulty != requested) {
        continue;
      }
      return GeneratedPuzzle(
        puzzle: SudokuBoard.fromValues(puzzleValues),
        solution: solution,
        difficulty: requested,
        seed: random.nextInt(0x7FFFFFFF),
        logicalStepCount: logicalResult.steps.length,
      );
    }
    return null;
  }

  List<int> _randomSolution(Random random) {
    final base = List<int>.generate(SudokuBoard.cellCount, (index) {
      final row = index ~/ 9;
      final column = index % 9;
      return (row * 3 + row ~/ 3 + column) % 9 + 1;
    }, growable: false);
    return _transformGrid(base, random);
  }

  List<int> _transformGrid(List<int> source, Random random) {
    final digitMap = List<int>.generate(9, (index) => index + 1)
      ..shuffle(random);
    final rows = _shuffledGroups(random);
    final columns = _shuffledGroups(random);
    final transpose = random.nextBool();

    return List<int>.generate(SudokuBoard.cellCount, (index) {
      final row = index ~/ 9;
      final column = index % 9;
      var sourceRow = rows[row];
      var sourceColumn = columns[column];
      if (transpose) {
        final temporary = sourceRow;
        sourceRow = sourceColumn;
        sourceColumn = temporary;
      }
      final value = source[sourceRow * 9 + sourceColumn];
      return value == 0 ? 0 : digitMap[value - 1];
    }, growable: false);
  }

  List<int> _shuffledGroups(Random random) {
    final groups = [0, 1, 2]..shuffle(random);
    final result = <int>[];
    for (final group in groups) {
      final members = [0, 1, 2]..shuffle(random);
      result.addAll(members.map((member) => group * 3 + member));
    }
    return result;
  }

  List<int> _carve(
    List<int> solution,
    Random random, {
    required int targetClues,
    required bool allowAsymmetric,
  }) {
    final puzzle = List<int>.of(solution);
    final pairs = <List<int>>[
      for (var index = 0; index <= 40; index++)
        index == 40 ? [index] : [index, 80 - index],
    ]..shuffle(random);

    var clues = SudokuBoard.cellCount;
    for (final pair in pairs) {
      final present = pair.where((index) => puzzle[index] != 0).toList();
      if (present.isEmpty || clues - present.length < targetClues) continue;
      final previous = [for (final index in present) puzzle[index]];
      for (final index in present) {
        puzzle[index] = 0;
      }
      if (!engine.analyzeSolutions(puzzle).hasUniqueSolution) {
        for (var offset = 0; offset < present.length; offset++) {
          puzzle[present[offset]] = previous[offset];
        }
      } else {
        clues -= present.length;
      }
    }

    if (allowAsymmetric && clues > targetClues) {
      final remaining = [
        for (var index = 0; index < SudokuBoard.cellCount; index++)
          if (puzzle[index] != 0) index,
      ]..shuffle(random);
      for (final index in remaining) {
        if (clues <= targetClues) break;
        final previous = puzzle[index];
        puzzle[index] = 0;
        if (!engine.analyzeSolutions(puzzle).hasUniqueSolution) {
          puzzle[index] = previous;
        } else {
          clues--;
        }
      }
    }
    return puzzle;
  }

  int _targetClueCount(PuzzleDifficulty difficulty, Random random) {
    final range = switch (difficulty) {
      PuzzleDifficulty.beginner => (40, 46),
      PuzzleDifficulty.easy => (33, 39),
      PuzzleDifficulty.medium => (27, 33),
      PuzzleDifficulty.hard => (22, 28),
    };
    return range.$1 + random.nextInt(range.$2 - range.$1 + 1);
  }

  static const Map<PuzzleDifficulty, String> _fallbackPuzzles = {
    PuzzleDifficulty.beginner: '760080009010050824000931007650070431080143050134090082300519000876020090500060043',
    PuzzleDifficulty.easy: '009760304670003000040100006056004009092000430400900650800001060000400012901057800',
    PuzzleDifficulty.medium: '007200000050000008008900140095000006020705080800000970084002700100000050000009860',
    PuzzleDifficulty.hard: '010004690098500200000000000006085000005000740000740900000000000001007460069800020',
  };
}
