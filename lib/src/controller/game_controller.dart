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

  factory GameController.practice(
    SudokuBoard puzzle,
    LogicalTechnique target, {
    List<CandidateRef> initialEliminations = const [],
  }) {
    final controller = GameController.fromPuzzle(
      puzzle,
      difficulty: target.difficulty,
    );
    final values = List<int>.of(puzzle.values);
    final excludedMasks = List<int>.filled(SudokuBoard.cellCount, 0);
    controller._practiceTarget = target;

    for (final candidate in initialEliminations) {
      if (candidate.index < 0 ||
          candidate.index >= SudokuBoard.cellCount ||
          candidate.digit < 1 ||
          candidate.digit > 9 ||
          values[candidate.index] != 0 ||
          controller.solution[candidate.index] == candidate.digit) {
        controller.dispose();
        throw ArgumentError('练习的前置候选排除不正确');
      }
      excludedMasks[candidate.index] |= SudokuEngine.bitFor(candidate.digit);
    }

    for (var count = 0; count < 600; count++) {
      final next = controller._logicalSolver.findNext(
        values: values,
        excludedMasks: excludedMasks,
      );
      var step = next;
      if (next?.technique != target &&
          (initialEliminations.isNotEmpty ||
              next == null ||
              next.difficulty.rank >= target.difficulty.rank)) {
        step =
            controller._logicalSolver.findTechnique(
              values: values,
              excludedMasks: excludedMasks,
              technique: target,
            ) ??
            next;
      }
      if (step == null) break;
      if (step.technique == target) {
        controller.board.replacePlayableValues(values);
        controller.excludedMasks.setAll(0, excludedMasks);
        controller.assistedCells.addAll(
          List<int>.generate(
            SudokuBoard.cellCount,
            (index) => index,
          ).where((index) => !puzzle.isGiven(index) && values[index] != 0),
        );
        controller.candidatesVisible = true;
        controller.statusMessage = '练习已就绪：点击“提示”观察${target.label}';
        return controller;
      }
      controller._logicalSolver.applyStep(
        values: values,
        excludedMasks: excludedMasks,
        step: step,
      );
    }

    controller.dispose();
    throw ArgumentError('这道练习题无法推进到 ${target.label}');
  }

  factory GameController.resume({
    required SudokuBoard puzzle,
    required List<int> values,
    required List<int> excludedMasks,
    required bool candidatesVisible,
    required Set<int> assistedCells,
    List<int>? manualCandidateMasks,
    PuzzleDifficulty? difficulty,
    int elapsedSeconds = 0,
    bool isPaused = false,
    int hintUseCount = 0,
    int basicSweepUseCount = 0,
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
        ) ||
        elapsedSeconds < 0 ||
        hintUseCount < 0 ||
        basicSweepUseCount < 0) {
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
    controller._elapsed = Duration(seconds: elapsedSeconds);
    controller.isPaused = isPaused;
    controller.hintUseCount = hintUseCount;
    controller.basicSweepUseCount = basicSweepUseCount;
    controller._runningSince = isPaused || controller.isComplete
        ? null
        : DateTime.now();
    controller.statusMessage = controller.isComplete
        ? '已恢复完成的题目'
        : isPaused
        ? '已恢复上次进度，当前处于暂停状态'
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
  final List<GameSnapshot> _redoHistory = [];
  final Set<int> assistedCells = {};
  LogicalTechnique? _practiceTarget;
  LogicalTechnique? get practiceTarget => _practiceTarget;
  bool practiceCompleted = false;

  int? selectedIndex;
  int? _candidateFocusDigit;
  bool noteMode = false;
  bool candidatesVisible = false;
  bool isPaused = false;
  int hintUseCount = 0;
  int basicSweepUseCount = 0;
  String statusMessage = '选择一个空格开始';
  LogicalStep? hintStep;
  int hintLevel = 0;
  Duration _elapsed = Duration.zero;
  DateTime? _runningSince = DateTime.now();

  bool get canUndo => _history.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;
  bool get isComplete =>
      board.isComplete && _engine.validate(board.values) == null;
  bool get hasHint => hintStep != null;
  Duration get elapsed {
    final runningSince = _runningSince;
    if (runningSince == null) return _elapsed;
    return _elapsed + DateTime.now().difference(runningSince);
  }

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
        ? (legalMask & ~excludedMasks[index]) | manualCandidateMasks[index]
        : manualCandidateMasks[index];
  }

  bool isHintPatternCell(int index) =>
      hintStep?.patternCells.contains(index) ?? false;

  bool isHintAffectedCell(int index) =>
      hintLevel >= 2 && (hintStep?.affectedCells.contains(index) ?? false);

  int hintPatternMaskAt(int index) => hintStep?.patternMaskAt(index) ?? 0;

  int hintEliminationMaskAt(int index) =>
      hintLevel >= 2 ? hintStep?.eliminationMaskAt(index) ?? 0 : 0;

  int hintCandidateColorMaskAt(int index, int color) =>
      hintLevel >= 2 ? hintStep?.candidateColorMaskAt(index, color) ?? 0 : 0;

  List<LogicalLink> get hintLinks =>
      hintLevel >= 2 ? hintStep?.links ?? const [] : const [];

  List<LogicalGroupLink> get hintGroupLinks =>
      hintLevel >= 2 ? hintStep?.groupLinks ?? const [] : const [];

  List<int> get hintChainCells =>
      hintLevel >= 2 ? hintStep?.chainCells ?? const [] : const [];

  List<CandidateRef> get hintChainNodes =>
      hintLevel >= 2 ? hintStep?.chainNodes ?? const [] : const [];

  List<List<CandidateRef>> get hintChainGroups =>
      hintLevel >= 2 ? hintStep?.chainGroups ?? const [] : const [];

  bool get hintIsLoop => hintLevel >= 2 && (hintStep?.isLoop ?? false);

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
    final digit = highlightedDigit;
    return digit != null && board.valueAt(index) == digit;
  }

  /// The selected filled digit, or the last candidate edited in this cell.
  int? get highlightedDigit {
    final selected = selectedIndex;
    if (selected == null || isPaused) return null;
    final value = board.valueAt(selected);
    return value == 0 ? _candidateFocusDigit : value;
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
    if (isPaused) return;
    selectedIndex = index;
    _candidateFocusDigit = null;
    notifyListeners();
  }

  void moveSelection({required int rowDelta, required int columnDelta}) {
    if (isPaused) return;
    final current = selectedIndex ?? 0;
    final row = ((current ~/ 9) + rowDelta).clamp(0, 8);
    final column = ((current % 9) + columnDelta).clamp(0, 8);
    selectCell(row * 9 + column);
  }

  void toggleNoteMode() {
    if (isPaused) return;
    noteMode = !noteMode;
    statusMessage = noteMode ? '候选模式已开启：可逐个标记小数字' : '填数模式已开启';
    notifyListeners();
  }

  void enterDigit(int digit) {
    if (isPaused) return;
    final index = selectedIndex;
    if (index == null || board.isGiven(index)) return;

    if (noteMode) {
      _toggleCandidate(index, digit);
      return;
    }

    if (board.valueAt(index) == digit) return;
    _pushHistory();
    board.setValue(index, digit);
    _candidateFocusDigit = null;
    assistedCells.remove(index);
    statusMessage = isComplete
        ? '完成了！'
        : isConflictingCell(index)
        ? '已填写 $digit；与同行、同列或同宫的数字重复'
        : '已填写 $digit';
    _stopClockIfComplete();
    notifyListeners();
  }

  void _toggleCandidate(int index, int digit) {
    if (board.valueAt(index) != 0) return;
    _candidateFocusDigit = digit;
    final bit = SudokuEngine.bitFor(digit);
    _pushHistory();
    if (candidatesVisible && (legalMaskAt(index) & bit) != 0) {
      // In automatic-candidate mode, legal digits toggle the solver-facing
      // exclusion mask. Clear a duplicate manual mark so an exclusion really
      // hides the candidate.
      manualCandidateMasks[index] &= ~bit;
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
    if (isPaused) return;
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
    _candidateFocusDigit = null;
    statusMessage = '已清除当前格';
    notifyListeners();
  }

  void showAllCandidates({bool resetManualEliminations = false}) {
    if (isPaused) return;
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
    if (isPaused) {
      return BasicSweepResult(
        values: List<int>.of(board.values),
        steps: const [],
        error: '请先继续游戏',
      );
    }
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
    basicSweepUseCount++;
    statusMessage =
        '完成 ${result.steps.length} 格：唯余 ${result.nakedSingleCount}，摒除 ${result.hiddenSingleCount}';
    _stopClockIfComplete();
    notifyListeners();
    return result;
  }

  void requestHint() {
    if (isPaused) return;
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

    final target = _practiceTarget;
    final step =
        (target == null
            ? null
            : _logicalSolver.findTechnique(
                values: board.values,
                excludedMasks: excludedMasks,
                technique: target,
              )) ??
        _logicalSolver.findNext(
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
    hintUseCount++;
    candidatesVisible = true;
    statusMessage = '已高亮下一步的观察区域';
    notifyListeners();
  }

  void revealHintExplanation() {
    if (isPaused) return;
    if (hintStep == null) return;
    hintLevel = 2;
    statusMessage = '已显示 ${hintStep!.technique.label} 的结构与结论';
    notifyListeners();
  }

  void dismissHint() {
    if (isPaused) return;
    if (hintStep == null) return;
    _clearHintInternal();
    statusMessage = '已关闭提示';
    notifyListeners();
  }

  void applyHintStep() {
    if (isPaused) return;
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
    if (step.technique == _practiceTarget) practiceCompleted = true;
    _stopClockIfComplete();
    notifyListeners();
  }

  void undo() {
    if (isPaused || _history.isEmpty) return;
    _clearHintInternal();
    final wasComplete = isComplete;
    _redoHistory.add(_snapshot());
    _restoreSnapshot(_history.removeLast());
    if (wasComplete && !isComplete) _resumeClock();
    statusMessage = '已撤销上一步';
    notifyListeners();
  }

  void redo() {
    if (isPaused || _redoHistory.isEmpty) return;
    _clearHintInternal();
    _history.add(_snapshot());
    _restoreSnapshot(_redoHistory.removeLast());
    _stopClockIfComplete();
    statusMessage = '已重做上一步';
    notifyListeners();
  }

  void togglePause() {
    if (isComplete) return;
    if (isPaused) {
      isPaused = false;
      _runningSince = DateTime.now();
      statusMessage = '已继续游戏';
    } else {
      _elapsed = elapsed;
      _runningSince = null;
      isPaused = true;
      _clearHintInternal();
      statusMessage = '游戏已暂停';
    }
    notifyListeners();
  }

  void _pushHistory() {
    _history.add(_snapshot());
    _redoHistory.clear();
    _clearHintInternal();
  }

  GameSnapshot _snapshot() => GameSnapshot(
    values: List<int>.of(board.values),
    excludedMasks: List<int>.of(excludedMasks),
    manualCandidateMasks: List<int>.of(manualCandidateMasks),
    candidatesVisible: candidatesVisible,
    assistedCells: Set<int>.of(assistedCells),
  );

  void _restoreSnapshot(GameSnapshot snapshot) {
    _candidateFocusDigit = null;
    board.replacePlayableValues(snapshot.values);
    for (var index = 0; index < excludedMasks.length; index++) {
      excludedMasks[index] = snapshot.excludedMasks[index];
      manualCandidateMasks[index] = snapshot.manualCandidateMasks[index];
    }
    candidatesVisible = snapshot.candidatesVisible;
    assistedCells
      ..clear()
      ..addAll(snapshot.assistedCells);
  }

  void _stopClockIfComplete() {
    if (!isComplete || _runningSince == null) return;
    _elapsed = elapsed;
    _runningSince = null;
  }

  void _resumeClock() {
    if (!isPaused && !isComplete && _runningSince == null) {
      _runningSince = DateTime.now();
    }
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
