import 'dart:typed_data';

class SudokuOcrResult {
  const SudokuOcrResult({
    required this.values,
    required this.confidences,
    required this.croppedImageBytes,
  });

  final List<int> values;
  final List<double?> confidences;
  final Uint8List croppedImageBytes;

  int get detectedCount => values.where((value) => value != 0).length;
}

class SudokuOcrService {
  const SudokuOcrService._();

  static const SudokuOcrService instance = SudokuOcrService._();
  static const bool isSupported = false;

  Future<SudokuOcrResult> recognize(Uint8List encodedImage) {
    throw UnsupportedError('浏览器预览不支持本地 TFLite 识别，请在 iOS 或 Android 设备上使用');
  }
}
