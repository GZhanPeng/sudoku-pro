import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_helper/src/controller/game_controller.dart';
import 'package:sudoku_helper/src/logic/logical_solver.dart';
import 'package:sudoku_helper/src/logic/practice_puzzles.dart';
import 'package:sudoku_helper/src/model/sudoku_board.dart';
import 'package:sudoku_helper/src/persistence/practice_progress_repository.dart';
import 'package:sudoku_helper/src/persistence/saved_game_repository.dart';
import 'package:sudoku_helper/src/settings/app_settings.dart';
import 'package:sudoku_helper/src/ui/home_screen.dart';

void main() {
  test(
    'display and new-game preferences survive a new settings controller',
    () {
      final storage = <String, String>{};
      final settings = AppSettingsController(
        read: (key) => storage[key],
        write: (key, value) => storage[key] = value,
      );
      addTearDown(settings.dispose);
      settings.update(
        settings.value.copyWith(
          themeMode: ThemeMode.dark,
          candidateSize: CandidateSize.large,
          highlightPeers: false,
          highlightSameDigit: false,
          candidateHighlightMode: CandidateHighlightMode.digitAndCell,
          warnCandidateConflicts: false,
          showTimer: false,
          autoCandidates: true,
          defaultDifficulty: PuzzleDifficulty.expert,
        ),
      );
      final restored = AppSettingsController(read: (key) => storage[key]);
      addTearDown(restored.dispose);
      expect(restored.value.toJson(), settings.value.toJson());
      settings.reset();
      final defaults = AppSettingsController(read: (key) => storage[key]);
      addTearDown(defaults.dispose);
      expect(defaults.value.toJson(), const AppPreferences().toJson());
    },
  );

  test('broken or partly unknown settings fall back safely', () {
    final broken = AppSettingsController(read: (_) => 'not json');
    addTearDown(broken.dispose);
    expect(broken.value.toJson(), const AppPreferences().toJson());
    final partial = AppPreferences.fromJson({
      'version': 1,
      'themeMode': 'unknown',
      'candidateSize': -1,
      'highlightPeers': 'false',
      'showTimer': false,
    });
    expect(partial.themeMode, ThemeMode.system);
    expect(partial.candidateSize, CandidateSize.standard);
    expect(partial.candidateHighlightMode, CandidateHighlightMode.digitOnly);
    expect(partial.highlightPeers, isTrue);
    expect(partial.showTimer, isFalse);
  });

  for (final version in [2, 3]) {
    test('version $version repository preserves manual candidate marks', () {
      final storage = <String, String>{};
      final repository = SavedGameRepository(
        read: (key) => storage[key],
        write: (key, value) => storage[key] = value,
        remove: storage.remove,
      );
      final original = GameController.fromPuzzle(
        SudokuBoard.parse(HomeScreen.samplePuzzle),
      );
      addTearDown(original.dispose);
      original.selectCell(2);
      original.toggleNoteMode();
      original.enterDigit(5);
      original.enterDigit(1);
      original.togglePause();
      repository.save(original);
      if (version == 2) {
        final key = storage.keys.single;
        final payload = jsonDecode(storage[key]!) as Map<String, dynamic>;
        payload['version'] = 2;
        storage[key] = jsonEncode(payload);
      }
      final restored = repository.load()!;
      addTearDown(restored.dispose);
      expect(restored.manualCandidateMasks, original.manualCandidateMasks);
      expect(
        restored.visibleCandidateMaskAt(2),
        original.visibleCandidateMaskAt(2),
      );
      expect(restored.isPaused, version == 3);
    });
  }

  test(
    'practice progress is durable, deduplicated and separate from games',
    () {
      final storage = <String, String>{};
      final repository = PracticeProgressRepository(
        read: (key) => storage[key],
        write: (key, value) => storage[key] = value,
      );
      final id = practicePuzzles.first.id;
      repository.markCompleted(id);
      repository.markCompleted(id);
      repository.markCompleted('unknown');
      final restored = PracticeProgressRepository(read: (key) => storage[key]);
      expect(restored.load(), {id});
      expect(storage.keys, [PracticeProgressRepository.storageKey]);
    },
  );

  test('practice rejects initial elimination of the solution', () {
    expect(
      () => GameController.practice(
        SudokuBoard.parse(HomeScreen.samplePuzzle),
        LogicalTechnique.nakedSingle,
        initialEliminations: const [CandidateRef(2, 4)],
      ),
      throwsArgumentError,
    );
  });
}
