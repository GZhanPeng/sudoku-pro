import 'dart:convert';

import 'package:flutter/material.dart';

import '../logic/logical_solver.dart';
import '../platform/local_store.dart';

enum CandidateSize {
  standard('标准', 8.5),
  large('较大', 10.5);

  const CandidateSize(this.label, this.fontSize);
  final String label;
  final double fontSize;
}

enum CandidateHighlightMode {
  off('不高亮候选'),
  digitOnly('仅候选数字'),
  digitAndCell('候选数字与格子');

  const CandidateHighlightMode(this.label);
  final String label;
}

class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.system,
    this.candidateSize = CandidateSize.standard,
    this.highlightPeers = true,
    this.highlightSameDigit = true,
    this.candidateHighlightMode = CandidateHighlightMode.digitOnly,
    this.warnCandidateConflicts = true,
    this.showTimer = true,
    this.autoCandidates = false,
    this.defaultDifficulty = PuzzleDifficulty.medium,
  });

  final ThemeMode themeMode;
  final CandidateSize candidateSize;
  final bool highlightPeers;
  final bool highlightSameDigit;
  final CandidateHighlightMode candidateHighlightMode;
  final bool warnCandidateConflicts;
  final bool showTimer;
  final bool autoCandidates;
  final PuzzleDifficulty defaultDifficulty;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    CandidateSize? candidateSize,
    bool? highlightPeers,
    bool? highlightSameDigit,
    CandidateHighlightMode? candidateHighlightMode,
    bool? warnCandidateConflicts,
    bool? showTimer,
    bool? autoCandidates,
    PuzzleDifficulty? defaultDifficulty,
  }) => AppPreferences(
    themeMode: themeMode ?? this.themeMode,
    candidateSize: candidateSize ?? this.candidateSize,
    highlightPeers: highlightPeers ?? this.highlightPeers,
    highlightSameDigit: highlightSameDigit ?? this.highlightSameDigit,
    candidateHighlightMode:
        candidateHighlightMode ?? this.candidateHighlightMode,
    warnCandidateConflicts:
        warnCandidateConflicts ?? this.warnCandidateConflicts,
    showTimer: showTimer ?? this.showTimer,
    autoCandidates: autoCandidates ?? this.autoCandidates,
    defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
  );

  Map<String, Object> toJson() => {
    'version': 1,
    'themeMode': themeMode.name,
    'candidateSize': candidateSize.name,
    'highlightPeers': highlightPeers,
    'highlightSameDigit': highlightSameDigit,
    'candidateHighlightMode': candidateHighlightMode.name,
    'warnCandidateConflicts': warnCandidateConflicts,
    'showTimer': showTimer,
    'autoCandidates': autoCandidates,
    'defaultDifficulty': defaultDifficulty.name,
  };

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    const defaults = AppPreferences();
    T enumValue<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((value) => value.name == name).firstOrNull ?? fallback;
    bool flag(String key, bool fallback) =>
        json[key] is bool ? json[key] as bool : fallback;
    if (json['version'] != 1) return defaults;
    return AppPreferences(
      themeMode: enumValue(
        ThemeMode.values,
        json['themeMode'],
        defaults.themeMode,
      ),
      candidateSize: enumValue(
        CandidateSize.values,
        json['candidateSize'],
        defaults.candidateSize,
      ),
      highlightPeers: flag('highlightPeers', defaults.highlightPeers),
      highlightSameDigit: flag(
        'highlightSameDigit',
        defaults.highlightSameDigit,
      ),
      candidateHighlightMode: enumValue(
        CandidateHighlightMode.values,
        json['candidateHighlightMode'],
        defaults.candidateHighlightMode,
      ),
      warnCandidateConflicts: flag(
        'warnCandidateConflicts',
        defaults.warnCandidateConflicts,
      ),
      showTimer: flag('showTimer', defaults.showTimer),
      autoCandidates: flag('autoCandidates', defaults.autoCandidates),
      defaultDifficulty: enumValue(
        PuzzleDifficulty.values,
        json['defaultDifficulty'],
        defaults.defaultDifficulty,
      ),
    );
  }
}

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    String? Function(String) read = readLocalValue,
    this.write = writeLocalValue,
  }) {
    try {
      final encoded = read(storageKey);
      if (encoded != null) {
        _value = AppPreferences.fromJson(
          jsonDecode(encoded) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      _value = const AppPreferences();
    }
  }

  static const storageKey = 'sudoku_helper.settings.v1';
  final void Function(String, String) write;
  AppPreferences _value = const AppPreferences();
  AppPreferences get value => _value;

  void update(AppPreferences preferences) {
    _value = preferences;
    write(storageKey, jsonEncode(preferences.toJson()));
    notifyListeners();
  }

  void reset() => update(const AppPreferences());
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()?.notifier;

  static AppPreferences preferencesOf(BuildContext context) =>
      maybeOf(context)?.value ?? const AppPreferences();
}
