import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_helper/src/logic/sudoku_engine.dart';
import 'package:sudoku_helper/src/model/sudoku_board.dart';

const puzzle =
    '530070000'
    '600195000'
    '098000060'
    '800060003'
    '400803001'
    '700020006'
    '060000280'
    '000419005'
    '000080079';

const solution =
    '534678912'
    '672195348'
    '198342567'
    '859761423'
    '426853791'
    '713924856'
    '961537284'
    '287419635'
    '345286179';

void main() {
  const engine = SudokuEngine();

  test('finds a unique solution', () {
    final board = SudokuBoard.parse(puzzle);
    final result = engine.analyzeSolutions(board.values);

    expect(result.solutionCount, 1);
    expect(result.firstSolution!.join(), solution);
  });

  test('computes legal candidates', () {
    final board = SudokuBoard.parse(puzzle);
    final mask = engine.legalMask(board.values, 2);

    expect(SudokuEngine.digitsInMask(mask), [1, 2, 4]);
  });

  test('basic sweep repeats naked and hidden singles to closure', () {
    final board = SudokuBoard.parse(puzzle);
    final result = engine.basicSweep(
      source: board.values,
      excludedMasks: List<int>.filled(81, 0),
      useNotes: false,
      expectedSolution: solution.split('').map(int.parse).toList(),
    );

    expect(result.error, isNull);
    expect(result.steps, isNotEmpty);
    expect(result.values.join(), solution);
    expect(result.nakedSingleCount + result.hiddenSingleCount, 51);
  });

  test('rejects a manual candidate elimination that forces a wrong value', () {
    final board = SudokuBoard.parse(puzzle);
    final exclusions = List<int>.filled(81, 0);
    exclusions[2] = SudokuEngine.bitFor(1) | SudokuEngine.bitFor(4);

    final result = engine.basicSweep(
      source: board.values,
      excludedMasks: exclusions,
      useNotes: true,
      expectedSolution: solution.split('').map(int.parse).toList(),
    );

    expect(result.hasError, isTrue);
    expect(result.values, board.values);
    expect(result.error, contains('候选标记存在矛盾'));
  });
}
