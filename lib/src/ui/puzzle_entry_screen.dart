import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controller/game_controller.dart';
import '../logic/sudoku_engine.dart';
import '../model/sudoku_board.dart';
import '../ocr/sudoku_ocr_service.dart'
    if (dart.library.js_interop) '../ocr/sudoku_ocr_stub.dart';
import 'game_screen.dart';

class PuzzleEntryScreen extends StatefulWidget {
  const PuzzleEntryScreen({super.key, this.startWithCamera = false});

  final bool startWithCamera;

  @override
  State<PuzzleEntryScreen> createState() => _PuzzleEntryScreenState();
}

class _PuzzleEntryScreenState extends State<PuzzleEntryScreen> {
  final _picker = ImagePicker();
  final _values = List<int>.filled(81, 0);
  final _confidences = List<double?>.filled(81, null);
  Uint8List? _referenceImage;
  int _selectedIndex = 0;
  bool _readingImage = false;
  String _recognitionMessage = SudokuOcrService.isSupported
      ? '拍照后会在设备本地识别，请逐格校对结果'
      : '网页版暂可导入照片辅助手动录入，本地 OCR 正在适配';

  @override
  void initState() {
    super.initState();
    if (widget.startWithCamera && SudokuOcrService.isSupported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImage(ImageSource.camera);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _readingImage = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2200,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _referenceImage = bytes;
        _recognitionMessage = SudokuOcrService.isSupported
            ? '正在本地识别棋盘和数字…'
            : '照片已导入，可参照图片逐格录入';
      });
      if (!SudokuOcrService.isSupported) return;
      final result = await SudokuOcrService.instance.recognize(bytes);
      if (!mounted) return;
      setState(() {
        _referenceImage = result.croppedImageBytes;
        _values.setAll(0, result.values);
        _confidences.setAll(0, result.confidences);
        _selectedIndex = 0;
        _recognitionMessage =
            '识别到 ${result.detectedCount} 个数字；红色格置信度较低或存在冲突，请校对';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _recognitionMessage = '自动识别失败，可参照照片手动录入';
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('照片识别失败：$error')));
    } finally {
      if (mounted) setState(() => _readingImage = false);
    }
  }

  void _enterDigit(int digit) {
    setState(() {
      _values[_selectedIndex] = digit;
      _confidences[_selectedIndex] = 1;
      if (_selectedIndex < 80) _selectedIndex++;
    });
  }

  void _clear() {
    setState(() {
      _values[_selectedIndex] = 0;
      _confidences[_selectedIndex] = null;
    });
  }

  Set<int> get _problemIndices {
    final problems = <int>{};
    for (var index = 0; index < 81; index++) {
      final confidence = _confidences[index];
      if (_values[index] != 0 && confidence != null && confidence < 0.62) {
        problems.add(index);
      }
    }
    for (final unit in SudokuEngine.allUnits) {
      final positionsByDigit = <int, List<int>>{};
      for (final index in unit) {
        final digit = _values[index];
        if (digit != 0) {
          positionsByDigit.putIfAbsent(digit, () => []).add(index);
        }
      }
      for (final positions in positionsByDigit.values) {
        if (positions.length > 1) problems.addAll(positions);
      }
    }
    return problems;
  }

  void _startGame() {
    if (_values.where((value) => value != 0).length < 17) {
      _showMessage('至少需要录入 17 个给定数字');
      return;
    }
    const engine = SudokuEngine();
    final analysis = engine.analyzeSolutions(_values);
    if (analysis.solutionCount != 1) {
      _showMessage(
        analysis.error ??
            (analysis.solutionCount > 1 ? '当前盘面存在多个解，请检查录入' : '当前盘面无解'),
      );
      return;
    }
    final puzzle = SudokuBoard.fromValues(_values);
    final controller = GameController.fromPuzzle(puzzle);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(controller: controller),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录入并校对'),
        actions: [
          IconButton(
            tooltip: '拍照',
            onPressed: _readingImage
                ? null
                : () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
          ),
          IconButton(
            tooltip: '从相册选择',
            onPressed: _readingImage
                ? null
                : () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      if (!SudokuOcrService.isSupported) ...[
                        Card(
                          elevation: 0,
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '网页版已支持拍照和选图；当前请对照照片录入，自动识别将在下一阶段接入。',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_readingImage) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 10),
                      ],
                      if (_referenceImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _referenceImage!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recognitionMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                      ],
                      AspectRatio(
                        aspectRatio: 1,
                        child: _EntryGrid(
                          values: _values,
                          selectedIndex: _selectedIndex,
                          problemIndices: _problemIndices,
                          onSelected: (index) =>
                              setState(() => _selectedIndex = index),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DigitPad(onDigit: _enterDigit, onClear: _clear),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _startGame,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          '验证并开始（已录入 ${_values.where((value) => value != 0).length} 格）',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EntryGrid extends StatelessWidget {
  const _EntryGrid({
    required this.values,
    required this.selectedIndex,
    required this.problemIndices,
    required this.onSelected,
  });

  final List<int> values;
  final int selectedIndex;
  final Set<int> problemIndices;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.onSurface, width: 2),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
        ),
        itemCount: 81,
        itemBuilder: (context, index) {
          final row = index ~/ 9;
          final column = index % 9;
          final value = values[index];
          final hasProblem = problemIndices.contains(index);
          return InkWell(
            onTap: () => onSelected(index),
            child: Container(
              decoration: BoxDecoration(
                color: index == selectedIndex
                    ? colors.primaryContainer
                    : hasProblem
                    ? colors.errorContainer
                    : colors.surface,
                border: Border(
                  right: BorderSide(
                    color: colors.outline,
                    width: column == 2 || column == 5 ? 2 : 0.45,
                  ),
                  bottom: BorderSide(
                    color: colors.outline,
                    width: row == 2 || row == 5 ? 2 : 0.45,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: value == 0
                  ? null
                  : Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: hasProblem ? colors.error : colors.onSurface,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _DigitPad extends StatelessWidget {
  const _DigitPad({required this.onDigit, required this.onClear});

  final ValueChanged<int> onDigit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var digit = 1; digit <= 9; digit++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FilledButton.tonal(
                onPressed: () => onDigit(digit),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: Size.zero,
                ),
                child: Text('$digit'),
              ),
            ),
          ),
        IconButton(
          tooltip: '清除',
          onPressed: onClear,
          icon: const Icon(Icons.backspace_outlined),
        ),
      ],
    );
  }
}
