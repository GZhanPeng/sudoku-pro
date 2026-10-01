import '../model/sudoku_board.dart';

enum SudokuUnitType { row, column, box }

enum BasicTechnique { nakedSingle, hiddenSingle }

class SolveAnalysis {
  const SolveAnalysis({
    required this.solutionCount,
    required this.firstSolution,
    this.error,
  });

  final int solutionCount;
  final List<int>? firstSolution;
  final String? error;

  bool get hasUniqueSolution => solutionCount == 1;
}

class BasicStep {
  const BasicStep({
    required this.technique,
    required this.index,
    required this.digit,
    this.unitType,
    this.unitIndex,
  });

  final BasicTechnique technique;
  final int index;
  final int digit;
  final SudokuUnitType? unitType;
  final int? unitIndex;

  int get row => index ~/ 9;
  int get column => index % 9;
}

class BasicSweepResult {
  const BasicSweepResult({
    required this.values,
    required this.steps,
    this.error,
  });

  final List<int> values;
  final List<BasicStep> steps;
  final String? error;

  bool get hasError => error != null;
  int get nakedSingleCount => steps
      .where((step) => step.technique == BasicTechnique.nakedSingle)
      .length;
  int get hiddenSingleCount => steps
      .where((step) => step.technique == BasicTechnique.hiddenSingle)
      .length;
}

class SudokuEngine {
  const SudokuEngine();

  static const int fullMask = 0x1FF;

  static final List<List<int>> rows = List.generate(
    9,
    (row) => List.generate(9, (column) => row * 9 + column),
  );

  static final List<List<int>> columns = List.generate(
    9,
    (column) => List.generate(9, (row) => row * 9 + column),
  );

  static final List<List<int>> boxes = List.generate(9, (box) {
    final startRow = (box ~/ 3) * 3;
    final startColumn = (box % 3) * 3;
    return [
      for (var row = startRow; row < startRow + 3; row++)
        for (var column = startColumn; column < startColumn + 3; column++)
          row * 9 + column,
    ];
  });

  static final List<List<int>> allUnits = [...rows, ...columns, ...boxes];

  static int bitFor(int digit) => 1 << (digit - 1);

  static int countBits(int mask) {
    var value = mask;
    var count = 0;
    while (value != 0) {
      value &= value - 1;
      count++;
    }
    return count;
  }

  static int singleDigit(int mask) {
    if (countBits(mask) != 1) return 0;
    for (var digit = 1; digit <= 9; digit++) {
      if ((mask & bitFor(digit)) != 0) return digit;
    }
    return 0;
  }

  static List<int> digitsInMask(int mask) => [
    for (var digit = 1; digit <= 9; digit++)
      if ((mask & bitFor(digit)) != 0) digit,
  ];

  String? validate(List<int> values) {
    if (values.length != SudokuBoard.cellCount) return '盘面必须包含 81 格';
    if (values.any((value) => value < 0 || value > 9)) {
      return '数字必须在 1 到 9 之间';
    }

    for (var unitIndex = 0; unitIndex < allUnits.length; unitIndex++) {
      var seen = 0;
      for (final index in allUnits[unitIndex]) {
        final digit = values[index];
        if (digit == 0) continue;
        final bit = bitFor(digit);
        if ((seen & bit) != 0) {
          if (unitIndex < 9) return '第 ${unitIndex + 1} 行有重复数字 $digit';
          if (unitIndex < 18) return '第 ${unitIndex - 8} 列有重复数字 $digit';
          return '第 ${unitIndex - 17} 宫有重复数字 $digit';
        }
        seen |= bit;
      }
    }
    return null;
  }

  int legalMask(List<int> values, int index) {
    if (values[index] != 0) return 0;
    final row = index ~/ 9;
    final column = index % 9;
    final box = (row ~/ 3) * 3 + column ~/ 3;
    var used = 0;
    for (final peer in rows[row]) {
      if (values[peer] != 0) used |= bitFor(values[peer]);
    }
    for (final peer in columns[column]) {
      if (values[peer] != 0) used |= bitFor(values[peer]);
    }
    for (final peer in boxes[box]) {
      if (values[peer] != 0) used |= bitFor(values[peer]);
    }
    return fullMask & ~used;
  }

  bool canPlace(List<int> values, int index, int digit) =>
      values[index] == 0 && (legalMask(values, index) & bitFor(digit)) != 0;

  SolveAnalysis analyzeSolutions(List<int> source, {int limit = 2}) {
    final values = List<int>.of(source);
    final validationError = validate(values);
    if (validationError != null) {
      return SolveAnalysis(
        solutionCount: 0,
        firstSolution: null,
        error: validationError,
      );
    }

    var count = 0;
    List<int>? firstSolution;

    void search() {
      if (count >= limit) return;
      var chosenIndex = -1;
      var chosenMask = 0;
      var smallest = 10;

      for (var index = 0; index < values.length; index++) {
        if (values[index] != 0) continue;
        final mask = legalMask(values, index);
        final size = countBits(mask);
        if (size == 0) return;
        if (size < smallest) {
          smallest = size;
          chosenIndex = index;
          chosenMask = mask;
          if (size == 1) break;
        }
      }

      if (chosenIndex == -1) {
        count++;
        firstSolution ??= List<int>.of(values);
        return;
      }

      for (final digit in digitsInMask(chosenMask)) {
        values[chosenIndex] = digit;
        search();
        values[chosenIndex] = 0;
        if (count >= limit) return;
      }
    }

    search();
    return SolveAnalysis(
      solutionCount: count,
      firstSolution: firstSolution,
      error: count == 0 ? '盘面无解' : null,
    );
  }

  BasicSweepResult basicSweep({
    required List<int> source,
    required List<int> excludedMasks,
    required bool useNotes,
    List<int>? expectedSolution,
  }) {
    final values = List<int>.of(source);
    final steps = <BasicStep>[];
    final validationError = validate(values);
    if (validationError != null) {
      return BasicSweepResult(
        values: values,
        steps: steps,
        error: validationError,
      );
    }

    int effectiveMask(int index) {
      final legal = legalMask(values, index);
      return useNotes ? legal & ~excludedMasks[index] : legal;
    }

    String? applyStep(BasicStep step) {
      if (expectedSolution != null &&
          expectedSolution[step.index] != step.digit) {
        return '候选标记存在矛盾：第 ${step.row + 1} 行第 ${step.column + 1} 列缺少正确候选';
      }
      values[step.index] = step.digit;
      steps.add(step);
      return null;
    }

    while (true) {
      BasicStep? nextStep;

      for (var index = 0; index < values.length; index++) {
        if (values[index] != 0) continue;
        final mask = effectiveMask(index);
        if (mask == 0) {
          return BasicSweepResult(
            values: List<int>.of(source),
            steps: const [],
            error: '候选标记存在矛盾：第 ${index ~/ 9 + 1} 行第 ${index % 9 + 1} 列已无候选数',
          );
        }
        if (countBits(mask) == 1) {
          nextStep = BasicStep(
            technique: BasicTechnique.nakedSingle,
            index: index,
            digit: singleDigit(mask),
          );
          break;
        }
      }

      if (nextStep == null) {
        final groupedUnits = <(SudokuUnitType, List<List<int>>)>[
          (SudokuUnitType.row, rows),
          (SudokuUnitType.column, columns),
          (SudokuUnitType.box, boxes),
        ];
        outer:
        for (final (type, units) in groupedUnits) {
          for (var unitIndex = 0; unitIndex < units.length; unitIndex++) {
            final unit = units[unitIndex];
            var placedMask = 0;
            for (final index in unit) {
              if (values[index] != 0) placedMask |= bitFor(values[index]);
            }
            for (var digit = 1; digit <= 9; digit++) {
              final bit = bitFor(digit);
              if ((placedMask & bit) != 0) continue;
              final possible = <int>[];
              for (final index in unit) {
                if (values[index] == 0 && (effectiveMask(index) & bit) != 0) {
                  possible.add(index);
                }
              }
              if (possible.isEmpty) {
                return BasicSweepResult(
                  values: List<int>.of(source),
                  steps: const [],
                  error: '候选标记存在矛盾：某个${_unitLabel(type)}无法放入数字 $digit',
                );
              }
              if (possible.length == 1) {
                nextStep = BasicStep(
                  technique: BasicTechnique.hiddenSingle,
                  index: possible.single,
                  digit: digit,
                  unitType: type,
                  unitIndex: unitIndex,
                );
                break outer;
              }
            }
          }
        }
      }

      if (nextStep == null) break;
      final error = applyStep(nextStep);
      if (error != null) {
        return BasicSweepResult(
          values: List<int>.of(source),
          steps: const [],
          error: error,
        );
      }
    }

    return BasicSweepResult(values: values, steps: steps);
  }

  static String _unitLabel(SudokuUnitType type) => switch (type) {
    SudokuUnitType.row => '行',
    SudokuUnitType.column => '列',
    SudokuUnitType.box => '宫',
  };
}
