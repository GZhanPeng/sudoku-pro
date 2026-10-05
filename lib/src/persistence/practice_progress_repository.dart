import 'dart:convert';

import '../logic/practice_puzzles.dart';
import '../platform/local_store.dart';

class PracticeProgressRepository {
  const PracticeProgressRepository({
    this.read = readLocalValue,
    this.write = writeLocalValue,
  });

  static const storageKey = 'sudoku_helper.practice.v1';
  final String? Function(String) read;
  final void Function(String, String) write;

  Set<String> load() {
    try {
      final encoded = read(storageKey);
      if (encoded == null) return {};
      final payload = jsonDecode(encoded) as Map<String, dynamic>;
      if (payload['version'] != 1 || payload['completed'] is! List) return {};
      final knownIds = practicePuzzles.map((lesson) => lesson.id).toSet();
      return (payload['completed'] as List)
          .whereType<String>()
          .where(knownIds.contains)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  void markCompleted(String lessonId) {
    if (!practicePuzzles.any((lesson) => lesson.id == lessonId)) return;
    final completed = load()..add(lessonId);
    write(
      storageKey,
      jsonEncode({'version': 1, 'completed': completed.toList()..sort()}),
    );
  }
}
