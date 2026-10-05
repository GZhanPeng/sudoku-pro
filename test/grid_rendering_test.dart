import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_helper/src/controller/game_controller.dart';
import 'package:sudoku_helper/src/model/sudoku_board.dart';
import 'package:sudoku_helper/src/ui/home_screen.dart';
import 'package:sudoku_helper/src/ui/sudoku_grid.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final side in [360.0, 527.5]) {
      testWidgets(
        'frame stays continuous over cell fills ($brightness, side=$side)',
        (tester) async {
          final game = GameController.fromPuzzle(
            SudokuBoard.parse(HomeScreen.samplePuzzle),
          );
          addTearDown(game.dispose);
          game.showAllCandidates();
          final colors = ColorScheme.fromSeed(
            seedColor: const Color(0xFF596044),
            brightness: brightness,
          );
          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(colorScheme: colors),
              home: Scaffold(
                body: Center(
                  child: SizedBox.square(
                    dimension: side,
                    child: RepaintBoundary(
                      key: boundaryKey,
                      child: AnimatedBuilder(
                        animation: game,
                        builder: (_, _) => SudokuGrid(controller: game),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          final expectedFrame = Color.lerp(
            colors.outline,
            colors.onSurface,
            0.35,
          )!.toARGB32();
          // Inspect the actual rendered frame in every row and column, including
          // highlighted edge cells. Widget decoration checks miss occlusion bugs.
          for (final selected in [0, 14, 2, 80]) {
            game.selectCell(selected);
            if (selected == 2) {
              game.requestHint();
              game.revealHintExplanation();
            }
            await tester.pump();
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final pixels = await tester.runAsync(() async {
              final rendered = await boundary.toImage(pixelRatio: 2);
              final data = await rendered.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              );
              final width = rendered.width;
              final height = rendered.height;
              rendered.dispose();
              return (data: data!, width: width, height: height);
            });
            for (var cell = 0; cell < 9; cell++) {
              final x = ((cell + 0.5) * pixels!.width / 9).floor();
              final y = ((cell + 0.5) * pixels.height / 9).floor();
              for (final point in [
                (x: x, y: 1),
                (x: x, y: pixels.height - 2),
                (x: 1, y: y),
                (x: pixels.width - 2, y: y),
              ]) {
                final offset = (point.y * pixels.width + point.x) * 4;
                for (var channel = 0; channel < 3; channel++) {
                  final expected = (expectedFrame >> (16 - channel * 8)) & 0xFF;
                  expect(
                    pixels.data.getUint8(offset + channel),
                    closeTo(expected, 1),
                    reason: 'Frame covered at $point, selected=$selected',
                  );
                }
                expect(pixels.data.getUint8(offset + 3), 255);
              }
            }
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
