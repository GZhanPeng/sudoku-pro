import 'dart:convert';

import '../controller/game_controller.dart';
import '../logic/logical_solver.dart';
import '../model/sudoku_board.dart';
import '../platform/local_store.dart';

class SavedGameRepository {
  const SavedGameRepository();

  static const _storageKey = 'sudoku_helper.saved_game.v1';

  bool get hasSavedGame => readLocalValue(_storageKey) != null;

  void save(GameController controller) {
    final payload = <String, Object?>{
      'version': 2,
      'puzzle': controller.puzzleValues,
      'values': controller.board.values.toList(growable: false),
      'excludedMasks': List<int>.of(controller.excludedMasks),
      'manualCandidateMasks': List<int>.of(controller.manualCandidateMasks),
      'candidatesVisible': controller.candidatesVisible,
      'assistedCells': controller.assistedCells.toList(growable: false),
      'difficulty': controller.difficulty?.index,
    };
    writeLocalValue(_storageKey, jsonEncode(payload));
  }

  GameController? load() {
    final encoded = readLocalValue(_storageKey);
    if (encoded == null) return null;
    try {
      final payload = jsonDecode(encoded) as Map<String, dynamic>;
      final version = payload['version'];
      if (version != 1 && version != 2) throw const FormatException();
      final puzzleValues = _readIntList(payload['puzzle']);
      final values = _readIntList(payload['values']);
      final excludedMasks = _readIntList(payload['excludedMasks']);
      final manualCandidateMasks = version == 2
          ? _readIntList(payload['manualCandidateMasks'])
          : List<int>.filled(SudokuBoard.cellCount, 0);
      final assistedCells = _readIntList(payload['assistedCells']).toSet();
      final candidatesVisible = payload['candidatesVisible'];
      if (candidatesVisible is! bool) throw const FormatException();
      final difficultyIndex = payload['difficulty'];
      final difficulty = difficultyIndex == null
          ? null
          : PuzzleDifficulty.values[difficultyIndex as int];

      return GameController.resume(
        puzzle: SudokuBoard.fromValues(puzzleValues),
        values: values,
        excludedMasks: excludedMasks,
        manualCandidateMasks: manualCandidateMasks,
        candidatesVisible: candidatesVisible,
        assistedCells: assistedCells,
        difficulty: difficulty,
      );
    } catch (_) {
      clear();
      return null;
    }
  }

  void clear() => removeLocalValue(_storageKey);

  List<int> _readIntList(Object? value) {
    if (value is! List) throw const FormatException();
    return value
        .map((item) {
          if (item is! int) throw const FormatException();
          return item;
        })
        .toList(growable: false);
  }
}
