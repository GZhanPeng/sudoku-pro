import 'package:flutter/foundation.dart';

import '../logic/logical_solver.dart';
import '../logic/sudoku_engine.dart';
import '../model/sudoku_board.dart';

class GameSnapshot {
  GameSnapshot({
    required this.values,
    required this.excludedMasks,
    required this.manualCandidateMasks,
    required this.candidatesVisible,
    required this.assistedCells,
  });

  final List<int> values;
  final List<int> excludedMasks;
  final List<int> manualCandidateMasks;
  final bool candidatesVisible;
  final Set<int> assistedCells;
}

class GameController extends ChangeNotifier {
  GameController._({
    required this.board,
    required this.solution,
    this.difficulty,
    this._engine = const SudokuEngine(),
  }) : _logicalSolver = const LogicalSolver(),
       excludedMasks = List<int>.filled(SudokuBoard.cellCount, 0),
       manualCandidateMasks = List<int>.filled(SudokuBoard.cellCount, 0);

  factory GameController.fromPuzzle(
    SudokuBoard puzzle, {
    PuzzleDifficulty? difficulty,
  }) {
    const engine = SudokuEngine();
    final analysis = engine.analyzeSolutions(puzzle.values);
    if (!analysis.hasUniqueSolution || analysis.firstSolution == null) {
      throw ArgumentError(
        analysis.error ?? (analysis.solutionCount > 1 ? '题目存在多个解' : '题目没有唯一解'),
      );
    }
    return GameController._(
      board: puzzle.copy(),
      solution: analysis.firstSolution!,
      difficulty: difficulty,
      engine: engine,
    );
  }

  factory GameController.resume({
    required SudokuBoard puzzle,
    required List<int> values,
    required List<int> excludedMasks,
    required bool candidatesVisible,
    required Set<int> assistedCells,
    List<int>? manualCandidateMasks,
    PuzzleDifficulty? difficulty,
  }) {
    final savedManualMasks =
        manualCandidateMasks ?? List<int>.filled(SudokuBoard.cellCount, 0);
    if (values.length != SudokuBoard.cellCount ||
        excludedMasks.length != SudokuBoard.cellCount ||
        savedManualMasks.length != SudokuBoard.cellCount) {
      throw const FormatException('保存的数独数据长度不正确');
    }
    if (excludedMasks.any((mask) => mask < 0 || mask > 0x1FF) ||
        savedManualMasks.any((mask) => mask < 0 || mask > 0x1FF) ||
        assistedCells.any(
          (index) => index < 0 || index >= SudokuBoard.cellCount,
        )) {
      throw const FormatException('保存的候选数数据不正确');
    }

    final controller = GameController.fromPuzzle(
      puzzle,
      difficulty: difficulty,
    );
    for (var index = 0; index < SudokuBoard.cellCount; index++) {
      if (puzzle.isGiven(index) && values[index] != puzzle.valueAt(index)) {
        throw const FormatException('保存的给定数与题目不一致');
      }
      final value = values[index];
      if (value < 0 || value > 9) {
        throw const FormatException('保存的盘面数字不正确');
      }
    }
    controller.board.replacePlayableValues(values);
    controller.excludedMasks.setAll(0, excludedMasks);
    controller.manualCandidateMasks.setAll(0, savedManualMasks);
    controller.candidatesVisible = candidatesVisible;
    controller.assistedCells.addAll(assistedCells);
    controller.statusMessage = controller.isComplete
        ? '已恢复完成的题目'
        : '已恢复上次的解题进度';
    return controller;
  }

  final SudokuEngine _engine;
  final LogicalSolver _logicalSolver;
  final SudokuBoard board;
  final List<int> solution;
  final PuzzleDifficulty? difficulty;
  final List<int> excludedMasks;
  final List<int> manualCandidateMasks;
  final List<GameSnapshot> _history = [];
  final Set<int> assistedCells = {};

  int? selectedIndex;
  bool noteMode = false;
  bool candidatesVisible = false;
  String statusMessage = '选择一个空格开始';
  LogicalStep? hintStep;
  int hintLevel = 0;

  bool get canUndo => _history.isNotEmpty;
  bool get isComplete =>
      board.isComplete && _engine.validate(board.values) == null;
  bool get hasHint => hintStep != null;

  List<int> get puzzleValues => List<int>.generate(
    SudokuBoard.cellCount,
    (index) => board.isGiven(index) ? board.valueAt(index) : 0,
    growable: false,
  );

  int valueAt(int index) => board.valueAt(index);
  bool isGiven(int index) => board.isGiven(index);
  int legalMaskAt(int index) => _engine.legalMask(board.values, index);

  int visibleCandidateMaskAt(int index) {
    if (board.valueAt(index) != 0) return 0;
    final legalMask = legalMaskAt(index);
    return candidatesVisible
        ? legalMask & ~excludedMasks[index]
        : legalMask & manualCandidateMasks[index];
  }

  bool isHintPatternCell(int index) =>
      hintStep?.patternCells.contains(index) ?? false;

  bool isHintAffectedCell(int index) =>
      hintLevel >= 2 && (hintStep?.affectedCells.contains(index) ?? false);

  int hintPatternMaskAt(int index) => hintStep?.patternMaskAt(index) ?? 0;

  int hintEliminationMaskAt(int index) =>
      hintLevel >= 2 ? hintStep?.eliminationMaskAt(index) ?? 0 : 0;

  List<LogicalLink> get hintLinks =>
      hintLevel >= 2 ? hintStep?.links ?? const [] : const [];

  bool isPeerOfSelected(int index) {
    final selected = selectedIndex;
    if (selected == null || selected == index) return false;
    final sameRow = selected ~/ 9 == index ~/ 9;
    final sameColumn = selected % 9 == index % 9;
    final sameBox =
        (selected ~/ 9) ~/ 3 == (index ~/ 9) ~/ 3 &&
        (selected % 9) ~/ 3 == (index % 9) ~/ 3;
    return sameRow || sameColumn || sameBox;
  }

  bool hasSameValueAsSelected(int index) {
    final selected = selectedIndex;
    if (selected == null) return false;
    final value = board.valueAt(selected);
    return value != 0 && board.valueAt(index) == value;
  }

  bool isConflictingCell(int index) {
    final value = board.valueAt(index);
    if (value == 0) return false;
    final row = index ~/ 9;
    final column = index % 9;
    final box = (row ~/ 3) * 3 + column ~/ 3;
    for (final unit in [
      SudokuEngine.rows[row],
      SudokuEngine.columns[column],
      SudokuEngine.boxes[box],
    ]) {
      if (unit.any((peer) => peer != index && board.valueAt(peer) == value)) {
        return true;
      }
    }
    return false;
  }

  void selectCell(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void toggleNoteMode() {
    noteMode = !noteMode;
    statusMessage = noteMode ? '候选模式已开启：可逐个标记小数字' : '填数模式已开启';
    notifyListeners();
  }

  void enterDigit(int digit) {
    final index = selectedIndex;
    if (index == null || board.isGiven(index)) return;

    if (noteMode) {
      _toggleCandidate(index, digit);
      return;
    }

    if (board.valueAt(index) == digit) return;
    _pushHistory();
    board.setValue(index, digit);
    assistedCells.remove(index);
    statusMessage = isComplete
        ? '完成了！'
        : isConflictingCell(index)
        ? '已填写 $digit；与同行、同列或同宫的数字重复'
        : '已填写 $digit';
    notifyListeners();
  }

  void _toggleCandidate(int index, int digit) {
    if (board.valueAt(index) != 0) return;
    final bit = SudokuEngine.bitFor(digit);
    if ((legalMaskAt(index) & bit) == 0) {
      statusMessage = '数字 $digit 不是这个格子的合法候选';
      notifyListeners();
      return;
    }
    _pushHistory();
    if (candidatesVisible) {
      if ((excludedMasks[index] & bit) != 0) {
        excludedMasks[index] &= ~bit;
        statusMessage = '恢复候选 $digit';
      } else {
        excludedMasks[index] |= bit;
        statusMessage = '排除候选 $digit';
      }
    } else if ((manualCandidateMasks[index] & bit) != 0) {
      manualCandidateMasks[index] &= ~bit;
      statusMessage = '取消手动候选 $digit';
    } else {
      manualCandidateMasks[index] |= bit;
      statusMessage = '标记手动候选 $digit';
    }
    notifyListeners();
  }

  void clearSelected() {
    final index = selectedIndex;
    if (index == null || board.isGiven(index)) return;
    if (board.valueAt(index) == 0 &&
        excludedMasks[index] == 0 &&
        manualCandidateMasks[index] == 0) {
      return;
    }
    _pushHistory();
    if (board.valueAt(index) != 0) board.setValue(index, 0);
    excludedMasks[index] = 0;
    manualCandidateMasks[index] = 0;
    assistedCells.remove(index);
    statusMessage = '已清除当前格';
    notifyListeners();
  }

  void showAllCandidates({bool resetManualEliminations = false}) {
    final changed =
        !candidatesVisible ||
        (resetManualEliminations &&
            (excludedMasks.any((mask) => mask != 0) ||
                manualCandidateMasks.any((mask) => mask != 0)));
    if (!changed) {
      statusMessage = '候选数已根据盘面实时更新';
      notifyListeners();
      return;
    }
    _pushHistory();
    candidatesVisible = true;
    if (resetManualEliminations) {
      for (var index = 0; index < excludedMasks.length; index++) {
        excludedMasks[index] = 0;
        manualCandidateMasks[index] = 0;
      }
      statusMessage = '已重置并全标所有合法候选';
    } else {
      statusMessage = '已全标所有合法候选';
    }
    notifyListeners();
  }

  BasicSweepResult applyBasicSweep() {
    final deadEnd = _deadEndMessage();
    if (deadEnd != null) {
      statusMessage = deadEnd;
      notifyListeners();
      return BasicSweepResult(
        values: List<int>.of(board.values),
        steps: const [],
        error: deadEnd,
      );
    }
    final result = _engine.basicSweep(
      source: board.values,
      excludedMasks: excludedMasks,
      useNotes: candidatesVisible,
      expectedSolution: solution,
    );
    if (result.hasError) {
      statusMessage = result.error!;
      notifyListeners();
      return result;
    }
    if (result.steps.isEmpty) {
      statusMessage = board.isComplete ? '已经完成' : '当前已无唯余或摒除步骤';
      notifyListeners();
      return result;
    }

    _pushHistory();
    board.replacePlayableValues(result.values);
    assistedCells.addAll(result.steps.map((step) => step.index));
    statusMessage =
        '完成 ${result.steps.length} 格：唯余 ${result.nakedSingleCount}，摒除 ${result.hiddenSingleCount}';
    notifyListeners();
    return result;
  }

  void requestHint() {
    if (board.isComplete) {
      statusMessage = '题目已经完成';
      notifyListeners();
      return;
    }
    final deadEnd = _deadEndMessage();
    if (deadEnd != null) {
      _clearHintInternal();
      statusMessage = deadEnd;
      notifyListeners();
      return;
    }
    for (var index = 0; index < SudokuBoard.cellCount; index++) {
      if (board.valueAt(index) == 0 &&
          (excludedMasks[index] & SudokuEngine.bitFor(solution[index])) != 0) {
        statusMessage =
            '候选标记存在矛盾：第 ${index ~/ 9 + 1} 行第 ${index % 9 + 1} 列缺少正确候选';
        notifyListeners();
        return;
      }
    }

    final step = _logicalSolver.findNext(
      values: board.values,
      excludedMasks: excludedMasks,
    );
    if (step == null) {
      _clearHintInternal();
      statusMessage = '当前技巧库未找到可解释的下一步';
      notifyListeners();
      return;
    }
    for (final elimination in step.eliminations) {
      if (solution[elimination.index] == elimination.digit) {
        _clearHintInternal();
        statusMessage = '候选标记存在矛盾，请检查手动排除';
        notifyListeners();
        return;
      }
    }
    hintStep = step;
    hintLevel = 1;
    candidatesVisible = true;
    statusMessage = '已高亮下一步的观察区域';
    notifyListeners();
  }

  void revealHintExplanation() {
    if (hintStep == null) return;
    hintLevel = 2;
    statusMessage = '已显示 ${hintStep!.technique.label} 的结构与结论';
    notifyListeners();
  }

  void dismissHint() {
    if (hintStep == null) return;
    _clearHintInternal();
    statusMessage = '已关闭提示';
    notifyListeners();
  }

  void applyHintStep() {
    final step = hintStep;
    if (step == null) return;
    _pushHistory();
    if (step.placementIndex case final index?) {
      board.setValue(index, step.placementDigit!);
      assistedCells.add(index);
    } else {
      for (final elimination in step.eliminations) {
        excludedMasks[elimination.index] |= SudokuEngine.bitFor(
          elimination.digit,
        );
      }
    }
    statusMessage =
        '已执行 ${step.technique.label}：${step.isPlacement ? '填入 1 格' : '删除 ${step.eliminations.length} 个候选'}';
    notifyListeners();
  }

  void undo() {
    if (_history.isEmpty) return;
    _clearHintInternal();
    final snapshot = _history.removeLast();
    board.replacePlayableValues(snapshot.values);
    for (var index = 0; index < excludedMasks.length; index++) {
      excludedMasks[index] = snapshot.excludedMasks[index];
      manualCandidateMasks[index] = snapshot.manualCandidateMasks[index];
    }
    candidatesVisible = snapshot.candidatesVisible;
    assistedCells
      ..clear()
      ..addAll(snapshot.assistedCells);
    statusMessage = '已撤销上一步';
    notifyListeners();
  }

  void _pushHistory() {
    _history.add(
      GameSnapshot(
        values: List<int>.of(board.values),
        excludedMasks: List<int>.of(excludedMasks),
        manualCandidateMasks: List<int>.of(manualCandidateMasks),
        candidatesVisible: candidatesVisible,
        assistedCells: Set<int>.of(assistedCells),
      ),
    );
    _clearHintInternal();
  }

  void _clearHintInternal() {
    hintStep = null;
    hintLevel = 0;
  }

  String? _deadEndMessage() {
    final analysis = _engine.analyzeSolutions(board.values, limit: 1);
    return analysis.solutionCount == 0 ? '当前盘面已无解，请撤销或检查已填数字' : null;
  }
}
