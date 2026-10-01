import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_helper/src/controller/game_controller.dart';
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

void main() {
  test('note mode marks candidates manually without triggering full marks', () {
    final controller = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(controller.dispose);
    controller.selectCell(2);

    controller.toggleNoteMode();
    expect(controller.noteMode, isTrue);
    expect(controller.candidatesVisible, isFalse);
    expect(controller.visibleCandidateMaskAt(2), 0);

    controller.enterDigit(1);
    expect(controller.visibleCandidateMaskAt(2), SudokuEngine.bitFor(1));
    expect(controller.candidatesVisible, isFalse);

    controller.showAllCandidates();
    expect(controller.candidatesVisible, isTrue);
    expect(controller.visibleCandidateMaskAt(2), controller.legalMaskAt(2));
  });

  test('manual candidate removals survive board updates', () {
    final controller = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(controller.dispose);

    controller.showAllCandidates();
    controller.selectCell(2);
    controller.toggleNoteMode();
    controller.enterDigit(1);
    expect(controller.visibleCandidateMaskAt(2) & SudokuEngine.bitFor(1), 0);

    controller.toggleNoteMode();
    controller.selectCell(3);
    controller.enterDigit(6);

    expect(controller.visibleCandidateMaskAt(2) & SudokuEngine.bitFor(1), 0);
  });

  test('a complete basic sweep can be undone as one action', () {
    final controller = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(controller.dispose);
    final original = controller.board.encode();

    final result = controller.applyBasicSweep();
    expect(result.steps, isNotEmpty);
    expect(controller.board.isComplete, isTrue);

    controller.undo();
    expect(controller.board.encode(), original);
  });

  test('saved progress can be restored without changing manual candidates', () {
    final original = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(original.dispose);

    original.showAllCandidates();
    original.selectCell(2);
    original.toggleNoteMode();
    original.enterDigit(1);
    original.toggleNoteMode();
    original.selectCell(3);
    original.enterDigit(6);

    final restored = GameController.resume(
      puzzle: SudokuBoard.fromValues(original.puzzleValues),
      values: original.board.values.toList(),
      excludedMasks: List<int>.of(original.excludedMasks),
      manualCandidateMasks: List<int>.of(original.manualCandidateMasks),
      candidatesVisible: original.candidatesVisible,
      assistedCells: Set<int>.of(original.assistedCells),
    );
    addTearDown(restored.dispose);

    expect(restored.board.encode(), original.board.encode());
    expect(restored.excludedMasks, original.excludedMasks);
    expect(restored.manualCandidateMasks, original.manualCandidateMasks);
    expect(restored.visibleCandidateMaskAt(2) & SudokuEngine.bitFor(1), 0);
    expect(restored.statusMessage, '已恢复上次的解题进度');
  });

  test('hint reveals progressively, applies one step, and can be undone', () {
    final controller = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(controller.dispose);
    final original = controller.board.encode();

    controller.requestHint();
    expect(controller.hintStep, isNotNull);
    expect(controller.hintLevel, 1);
    expect(controller.candidatesVisible, isTrue);

    controller.revealHintExplanation();
    expect(controller.hintLevel, 2);
    final step = controller.hintStep!;

    controller.applyHintStep();
    expect(controller.hintStep, isNull);
    expect(controller.canUndo, isTrue);
    if (step.isPlacement) {
      expect(controller.valueAt(step.placementIndex!), step.placementDigit);
    } else {
      for (final elimination in step.eliminations) {
        expect(
          controller.excludedMasks[elimination.index] &
              SudokuEngine.bitFor(elimination.digit),
          isNonZero,
        );
      }
    }

    controller.undo();
    expect(controller.board.encode(), original);
  });
}
