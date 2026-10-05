import 'dart:convert';

import '../controller/game_controller.dart';
import '../logic/logical_solver.dart';
import '../model/sudoku_board.dart';
import '../platform/local_store.dart';

class SavedGameRepository {
  const SavedGameRepository({
    this.read = readLocalValue,
    this.write = writeLocalValue,
    this.remove = removeLocalValue,
  });

  final String? Function(String) read;
  final void Function(String, String) write;
  final void Function(String) remove;

  static const _storageKey = 'sudoku_helper.saved_game.v1';

  bool get hasSavedGame => read(_storageKey) != null;

  void save(GameController controller) {
    final payload = <String, Object?>{
      'version': 3,
      'puzzle': controller.puzzleValues,
      'values': controller.board.values.toList(growable: false),
      'excludedMasks': List<int>.of(controller.excludedMasks),
      'manualCandidateMasks': List<int>.of(controller.manualCandidateMasks),
      'candidatesVisible': controller.candidatesVisible,
      'assistedCells': controller.assistedCells.toList(growable: false),
      'difficulty': controller.difficulty?.index,
      'elapsedSeconds': controller.elapsed.inSeconds,
      'isPaused': controller.isPaused,
      'hintUseCount': controller.hintUseCount,
      'basicSweepUseCount': controller.basicSweepUseCount,
    };
    write(_storageKey, jsonEncode(payload));
  }

  GameController? load() {
    final encoded = read(_storageKey);
    if (encoded == null) return null;
    try {
      final payload = jsonDecode(encoded) as Map<String, dynamic>;
      final version = payload['version'];
      if (version != 1 && version != 2 && version != 3) {
        throw const FormatException();
      }
      final puzzleValues = _readIntList(payload['puzzle']);
      final values = _readIntList(payload['values']);
      final excludedMasks = _readIntList(payload['excludedMasks']);
      final manualCandidateMasks = version == 2 || version == 3
          ? _readIntList(payload['manualCandidateMasks'])
          : List<int>.filled(SudokuBoard.cellCount, 0);
      final assistedCells = _readIntList(payload['assistedCells']).toSet();
      final candidatesVisible = payload['candidatesVisible'];
      if (candidatesVisible is! bool) throw const FormatException();
      final difficultyIndex = payload['difficulty'];
      final difficulty = difficultyIndex == null
          ? null
          : PuzzleDifficulty.values[difficultyIndex as int];
      final elapsedSeconds = version == 3
          ? _readNonNegativeInt(payload['elapsedSeconds'])
          : 0;
      final isPaused = version == 3 ? payload['isPaused'] : false;
      final hintUseCount = version == 3
          ? _readNonNegativeInt(payload['hintUseCount'])
          : 0;
      final basicSweepUseCount = version == 3
          ? _readNonNegativeInt(payload['basicSweepUseCount'])
          : 0;
      if (isPaused is! bool) throw const FormatException();

      return GameController.resume(
        puzzle: SudokuBoard.fromValues(puzzleValues),
        values: values,
        excludedMasks: excludedMasks,
        manualCandidateMasks: manualCandidateMasks,
        candidatesVisible: candidatesVisible,
        assistedCells: assistedCells,
        difficulty: difficulty,
        elapsedSeconds: elapsedSeconds,
        isPaused: isPaused,
        hintUseCount: hintUseCount,
        basicSweepUseCount: basicSweepUseCount,
      );
    } catch (_) {
      clear();
      return null;
    }
  }

  void clear() => remove(_storageKey);

  List<int> _readIntList(Object? value) {
    if (value is! List) throw const FormatException();
    return value
        .map((item) {
          if (item is! int) throw const FormatException();
          return item;
        })
        .toList(growable: false);
  }

  int _readNonNegativeInt(Object? value) {
    if (value is! int || value < 0) throw const FormatException();
    return value;
  }
}
