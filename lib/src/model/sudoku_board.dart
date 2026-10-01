import 'dart:collection';

class SudokuBoard {
  SudokuBoard._(List<int> values, Set<int> givens)
    : _values = List<int>.of(values),
      givens = Set<int>.of(givens) {
    if (_values.length != cellCount) {
      throw ArgumentError.value(_values.length, 'values.length', '必须为 81');
    }
    if (_values.any((value) => value < 0 || value > 9)) {
      throw ArgumentError('盘面只能包含 0 到 9');
    }
  }

  factory SudokuBoard.empty() =>
      SudokuBoard._(List<int>.filled(cellCount, 0), <int>{});

  factory SudokuBoard.fromValues(
    List<int> values, {
    bool markFilledAsGivens = true,
  }) {
    final givens = <int>{};
    if (markFilledAsGivens) {
      for (var index = 0; index < values.length; index++) {
        if (values[index] != 0) givens.add(index);
      }
    }
    return SudokuBoard._(values, givens);
  }

  factory SudokuBoard.parse(String encoded, {bool markFilledAsGivens = true}) {
    final compact = encoded.replaceAll(RegExp(r'\s'), '');
    if (compact.length != cellCount) {
      throw const FormatException('数独字符串必须正好包含 81 个字符');
    }
    final values = compact
        .split('')
        .map((character) {
          if (character == '.' || character == '0') return 0;
          final digit = int.tryParse(character);
          if (digit == null || digit < 1 || digit > 9) {
            throw FormatException('无法识别字符：$character');
          }
          return digit;
        })
        .toList(growable: false);
    return SudokuBoard.fromValues(
      values,
      markFilledAsGivens: markFilledAsGivens,
    );
  }

  static const int side = 9;
  static const int cellCount = 81;

  final List<int> _values;
  final Set<int> givens;

  UnmodifiableListView<int> get values => UnmodifiableListView(_values);
  int valueAt(int index) => _values[index];
  bool isGiven(int index) => givens.contains(index);
  bool get isComplete => _values.every((value) => value != 0);
  int get filledCount => _values.where((value) => value != 0).length;

  void setValue(int index, int value) {
    if (index < 0 || index >= cellCount) {
      throw RangeError.index(index, _values, 'index');
    }
    if (value < 0 || value > 9) {
      throw ArgumentError.value(value, 'value', '必须在 0 到 9 之间');
    }
    if (isGiven(index)) throw StateError('题目给定数字不能修改');
    _values[index] = value;
  }

  void replacePlayableValues(List<int> values) {
    if (values.length != cellCount) {
      throw ArgumentError.value(values.length, 'values.length', '必须为 81');
    }
    for (var index = 0; index < cellCount; index++) {
      if (!isGiven(index)) _values[index] = values[index];
    }
  }

  SudokuBoard copy() => SudokuBoard._(_values, givens);

  String encode({String empty = '0'}) =>
      _values.map((value) => value == 0 ? empty : '$value').join();
}
