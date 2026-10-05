import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_helper/src/controller/game_controller.dart';
import 'package:sudoku_helper/src/logic/logical_solver.dart';
import 'package:sudoku_helper/src/logic/practice_puzzles.dart';
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

const groupedAicPuzzle =
    '345128900'
    '976000281'
    '281000345'
    '000000010'
    '100600030'
    '402081509'
    '704000128'
    '819040653'
    '023810794';

void main() {
  test('practice can prepare a grouped AIC lesson', () {
    final controller = GameController.practice(
      SudokuBoard.parse(groupedAicPuzzle),
      LogicalTechnique.groupedAic,
    );
    addTearDown(controller.dispose);

    controller.requestHint();
    expect(controller.hintStep?.technique, LogicalTechnique.groupedAic);
    expect(
      controller.hintStep?.chainGroups.any((group) => group.length > 1),
      isTrue,
    );
  });

  for (final practice in practicePuzzles) {
    test('practice prepares ${practice.technique.label} as the next step', () {
      final controller = GameController.practice(
        SudokuBoard.parse(practice.puzzle),
        practice.technique,
        initialEliminations: practice.initialEliminations,
      );
      addTearDown(controller.dispose);

      expect(controller.candidatesVisible, isTrue);
      expect(controller.statusMessage, contains(practice.technique.label));
      controller.requestHint();
      expect(controller.hintStep?.technique, practice.technique);
      for (var index = 0; index < SudokuBoard.cellCount; index++) {
        if (controller.valueAt(index) != 0) {
          expect(controller.valueAt(index), controller.solution[index]);
        } else {
          expect(
            controller.excludedMasks[index] &
                SudokuEngine.bitFor(controller.solution[index]),
            0,
          );
        }
      }
      final step = controller.hintStep!;
      for (final elimination in step.eliminations) {
        expect(
          elimination.digit,
          isNot(controller.solution[elimination.index]),
        );
      }
      controller.applyHintStep();
      expect(controller.practiceCompleted, isTrue);
    });
  }

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

  test('manual note mode accepts a candidate that conflicts with the row', () {
    final controller = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(controller.dispose);
    final bit = SudokuEngine.bitFor(5);
    controller.selectCell(2);
    controller.toggleNoteMode();

    expect(controller.legalMaskAt(2) & bit, 0);
    controller.enterDigit(5);

    expect(controller.manualCandidateMasks[2] & bit, bit);
    expect(controller.visibleCandidateMaskAt(2) & bit, bit);
    expect(controller.statusMessage, '标记手动候选 5');

    controller.enterDigit(5);
    expect(controller.manualCandidateMasks[2] & bit, 0);
    expect(controller.visibleCandidateMaskAt(2) & bit, 0);
  });

  test('full-candidate mode can add an explicitly wrong manual candidate', () {
    final controller = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(controller.dispose);
    final bit = SudokuEngine.bitFor(5);
    controller.showAllCandidates();
    controller.selectCell(2);
    controller.toggleNoteMode();

    expect(controller.visibleCandidateMaskAt(2) & bit, 0);
    controller.enterDigit(5);

    expect(controller.candidatesVisible, isTrue);
    expect(controller.manualCandidateMasks[2] & bit, bit);
    expect(controller.visibleCandidateMaskAt(2) & bit, bit);
    expect(controller.excludedMasks[2] & bit, 0);
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

  test('a locally legal wrong digit is accepted as a normal trial', () {
    final controller = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(controller.dispose);

    controller.selectCell(2);
    controller.enterDigit(1);

    expect(controller.valueAt(2), 1);
    expect(controller.statusMessage, '已填写 1');
    expect(controller.canUndo, isTrue);
  });

  test('a conflicting digit is accepted and marked instead of blocked', () {
    final controller = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(controller.dispose);

    controller.selectCell(2);
    controller.enterDigit(5);

    expect(controller.valueAt(2), 5);
    expect(controller.isConflictingCell(2), isTrue);
    expect(controller.isConflictingCell(0), isTrue);
    expect(controller.statusMessage, contains('数字重复'));
    expect(controller.isComplete, isFalse);
  });

  test('assistance reports a dead end without deleting a wrong trial', () {
    final controller = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(controller.dispose);
    controller.selectCell(2);
    controller.enterDigit(1);

    final result = controller.applyBasicSweep();

    expect(result.hasError, isTrue);
    expect(controller.valueAt(2), 1);
    expect(controller.statusMessage, contains('当前盘面已无解'));

    controller.requestHint();
    expect(controller.hintStep, isNull);
    expect(controller.statusMessage, contains('当前盘面已无解'));
  });

  test('saved progress can restore a conflicting trial', () {
    final original = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(original.dispose);
    original.selectCell(2);
    original.enterDigit(5);

    final restored = GameController.resume(
      puzzle: SudokuBoard.fromValues(original.puzzleValues),
      values: original.board.values.toList(),
      excludedMasks: List<int>.of(original.excludedMasks),
      manualCandidateMasks: List<int>.of(original.manualCandidateMasks),
      candidatesVisible: original.candidatesVisible,
      assistedCells: Set<int>.of(original.assistedCells),
    );
    addTearDown(restored.dispose);

    expect(restored.valueAt(2), 5);
    expect(restored.isConflictingCell(2), isTrue);
    expect(restored.statusMessage, '已恢复上次的解题进度');
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

  test('undo and redo restore the same playable state', () {
    final controller = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(controller.dispose);
    controller.selectCell(2);
    controller.enterDigit(1);

    expect(controller.canUndo, isTrue);
    expect(controller.canRedo, isFalse);

    controller.undo();
    expect(controller.valueAt(2), 0);
    expect(controller.canRedo, isTrue);

    controller.redo();
    expect(controller.valueAt(2), 1);
    expect(controller.canUndo, isTrue);
    expect(controller.canRedo, isFalse);
  });

  test('a new edit clears the redo history', () {
    final controller = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    addTearDown(controller.dispose);
    controller.selectCell(2);
    controller.enterDigit(1);
    controller.undo();
    expect(controller.canRedo, isTrue);

    controller.enterDigit(2);

    expect(controller.valueAt(2), 2);
    expect(controller.canRedo, isFalse);
  });

  test('pause and session statistics survive resume data', () {
    final controller = GameController.resume(
      puzzle: SudokuBoard.parse(puzzle),
      values: SudokuBoard.parse(puzzle).values.toList(),
      excludedMasks: List<int>.filled(SudokuBoard.cellCount, 0),
      candidatesVisible: false,
      assistedCells: <int>{},
      elapsedSeconds: 125,
      isPaused: true,
      hintUseCount: 3,
      basicSweepUseCount: 2,
    );
    addTearDown(controller.dispose);

    expect(controller.elapsed, const Duration(seconds: 125));
    expect(controller.isPaused, isTrue);
    expect(controller.hintUseCount, 3);
    expect(controller.basicSweepUseCount, 2);

    controller.togglePause();
    expect(controller.isPaused, isFalse);
    expect(controller.statusMessage, '已继续游戏');
  });

  test('successful assistance updates completion statistics', () {
    final hintController = GameController.fromPuzzle(SudokuBoard.parse(puzzle));
    final sweepController = GameController.fromPuzzle(
      SudokuBoard.parse(puzzle),
    );
    addTearDown(hintController.dispose);
    addTearDown(sweepController.dispose);

    hintController.requestHint();
    expect(hintController.hintUseCount, 1);

    final result = sweepController.applyBasicSweep();
    expect(result.steps, isNotEmpty);
    expect(sweepController.basicSweepUseCount, 1);
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
