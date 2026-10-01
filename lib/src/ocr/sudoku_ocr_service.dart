import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:tflite_flutter/tflite_flutter.dart';

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
  SudokuOcrService._();

  static final SudokuOcrService instance = SudokuOcrService._();
  static const bool isSupported = true;

  _YoloDetector? _boardDetector;
  _YoloDetector? _digitDetector;

  Future<SudokuOcrResult> recognize(Uint8List encodedImage) async {
    var source = image.decodeImage(encodedImage);
    if (source == null) throw const FormatException('无法解码照片');
    source = image.bakeOrientation(source);

    _boardDetector ??= await _YoloDetector.load(
      'assets/models/sudoku_float16.tflite',
      confidenceThreshold: 0.75,
    );
    _digitDetector ??= await _YoloDetector.load(
      'assets/models/digits_float16.tflite',
      confidenceThreshold: 0.45,
    );

    final boardDetections = _boardDetector!.detect(source);
    if (boardDetections.isEmpty) {
      throw const FormatException('没有检测到完整的 9×9 数独棋盘');
    }
    final boardBox = boardDetections.reduce(
      (best, candidate) =>
          candidate.confidence > best.confidence ? candidate : best,
    );
    final crop = _safeCrop(source, boardBox);
    final digitDetections = _digitDetector!.detect(crop);

    final values = List<int>.filled(81, 0);
    final confidences = List<double?>.filled(81, null);
    for (final detection in digitDetections) {
      final digit = detection.classId;
      if (digit < 1 || digit > 9) continue;
      final centerX = detection.x + detection.width / 2;
      final centerY = detection.y + detection.height / 2;
      final column = (centerX / crop.width * 9).floor().clamp(0, 8);
      final row = (centerY / crop.height * 9).floor().clamp(0, 8);
      final index = row * 9 + column;
      final previousConfidence = confidences[index] ?? -1;
      if (detection.confidence > previousConfidence) {
        values[index] = digit;
        confidences[index] = detection.confidence;
      }
    }

    return SudokuOcrResult(
      values: values,
      confidences: confidences,
      croppedImageBytes: image.encodeJpg(crop, quality: 92),
    );
  }

  image.Image _safeCrop(image.Image source, _Detection box) {
    final x = box.x.floor().clamp(0, source.width - 1);
    final y = box.y.floor().clamp(0, source.height - 1);
    final right = (box.x + box.width).ceil().clamp(x + 1, source.width);
    final bottom = (box.y + box.height).ceil().clamp(y + 1, source.height);
    return image.copyCrop(
      source,
      x: x,
      y: y,
      width: right - x,
      height: bottom - y,
    );
  }
}

class _YoloDetector {
  _YoloDetector._({
    required this._interpreter,
    required this.confidenceThreshold,
  });

  static Future<_YoloDetector> load(
    String assetPath, {
    required double confidenceThreshold,
  }) async {
    final options = InterpreterOptions()..threads = 4;
    final interpreter = await Interpreter.fromAsset(
      assetPath,
      options: options,
    );
    return _YoloDetector._(
      interpreter: interpreter,
      confidenceThreshold: confidenceThreshold,
    );
  }

  final Interpreter _interpreter;
  final double confidenceThreshold;

  List<_Detection> detect(image.Image source) {
    final inputTensor = _interpreter.getInputTensor(0);
    final inputShape = inputTensor.shape;
    if (inputShape.length != 4 || inputShape.last != 3) {
      throw StateError('不支持的模型输入形状：$inputShape');
    }
    final inputHeight = inputShape[1];
    final inputWidth = inputShape[2];
    final prepared = _letterbox(source, inputWidth, inputHeight);
    inputTensor.data = prepared.bytes.buffer.asUint8List();
    _interpreter.invoke();

    final outputTensor = _interpreter.getOutputTensor(0);
    final shape = outputTensor.shape;
    if (shape.length != 3 || shape.first != 1) {
      throw StateError('不支持的模型输出形状：$shape');
    }
    final output = outputTensor.data.buffer.asFloat32List();
    final channelFirst = shape[1] < shape[2];
    final channels = channelFirst ? shape[1] : shape[2];
    final boxCount = channelFirst ? shape[2] : shape[1];
    final classCount = channels - 4;

    double valueAt(int box, int channel) => channelFirst
        ? output[channel * boxCount + box]
        : output[box * channels + channel];

    final candidates = <_Detection>[];
    for (var boxIndex = 0; boxIndex < boxCount; boxIndex++) {
      var bestClass = -1;
      var bestScore = 0.0;
      for (var classIndex = 0; classIndex < classCount; classIndex++) {
        final score = valueAt(boxIndex, classIndex + 4);
        if (score > bestScore) {
          bestScore = score;
          bestClass = classIndex;
        }
      }
      if (bestScore < confidenceThreshold || bestClass < 0) continue;

      final centerX = valueAt(boxIndex, 0);
      final centerY = valueAt(boxIndex, 1);
      final width = valueAt(boxIndex, 2);
      final height = valueAt(boxIndex, 3);
      final x = (centerX - width / 2 - prepared.padX) / prepared.scale;
      final y = (centerY - height / 2 - prepared.padY) / prepared.scale;
      final mappedWidth = width / prepared.scale;
      final mappedHeight = height / prepared.scale;
      if (mappedWidth <= 1 || mappedHeight <= 1) continue;

      final left = x.clamp(0.0, source.width.toDouble());
      final top = y.clamp(0.0, source.height.toDouble());
      final right = (x + mappedWidth).clamp(0.0, source.width.toDouble());
      final bottom = (y + mappedHeight).clamp(0.0, source.height.toDouble());
      if (right <= left || bottom <= top) continue;
      candidates.add(
        _Detection(
          classId: bestClass,
          confidence: bestScore,
          x: left,
          y: top,
          width: right - left,
          height: bottom - top,
        ),
      );
    }
    return _nonMaximumSuppression(candidates, threshold: 0.45);
  }

  _PreparedInput _letterbox(
    image.Image source,
    int targetWidth,
    int targetHeight,
  ) {
    final scale = math.min(
      targetWidth / source.width,
      targetHeight / source.height,
    );
    final resizedWidth = (source.width * scale).round();
    final resizedHeight = (source.height * scale).round();
    final resized = image.copyResize(
      source,
      width: resizedWidth,
      height: resizedHeight,
      interpolation: image.Interpolation.linear,
    );
    final canvas = image.Image(width: targetWidth, height: targetHeight);
    image.fill(canvas, color: image.ColorRgb8(114, 114, 114));
    final padX = (targetWidth - resizedWidth) ~/ 2;
    final padY = (targetHeight - resizedHeight) ~/ 2;
    image.compositeImage(canvas, resized, dstX: padX, dstY: padY);

    final floats = Float32List(targetWidth * targetHeight * 3);
    var offset = 0;
    for (var y = 0; y < targetHeight; y++) {
      for (var x = 0; x < targetWidth; x++) {
        final pixel = canvas.getPixel(x, y);
        floats[offset++] = pixel.r.toDouble() / 255;
        floats[offset++] = pixel.g.toDouble() / 255;
        floats[offset++] = pixel.b.toDouble() / 255;
      }
    }
    return _PreparedInput(
      bytes: floats,
      scale: scale,
      padX: padX.toDouble(),
      padY: padY.toDouble(),
    );
  }

  List<_Detection> _nonMaximumSuppression(
    List<_Detection> candidates, {
    required double threshold,
  }) {
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    final kept = <_Detection>[];
    for (final candidate in candidates) {
      if (kept.every(
        (other) => _intersectionOverUnion(candidate, other) <= threshold,
      )) {
        kept.add(candidate);
      }
    }
    return kept;
  }

  double _intersectionOverUnion(_Detection a, _Detection b) {
    final left = math.max(a.x, b.x);
    final top = math.max(a.y, b.y);
    final right = math.min(a.x + a.width, b.x + b.width);
    final bottom = math.min(a.y + a.height, b.y + b.height);
    final intersection =
        math.max(0.0, right - left) * math.max(0.0, bottom - top);
    final union = a.width * a.height + b.width * b.height - intersection;
    return union <= 0 ? 0 : intersection / union;
  }
}

class _PreparedInput {
  const _PreparedInput({
    required this.bytes,
    required this.scale,
    required this.padX,
    required this.padY,
  });

  final Float32List bytes;
  final double scale;
  final double padX;
  final double padY;
}

class _Detection {
  const _Detection({
    required this.classId,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int classId;
  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;
}
