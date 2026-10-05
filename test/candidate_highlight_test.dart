import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_helper/src/controller/game_controller.dart';
import 'package:sudoku_helper/src/logic/sudoku_engine.dart';
import 'package:sudoku_helper/src/model/sudoku_board.dart';
import 'package:sudoku_helper/src/settings/app_settings.dart';
import 'package:sudoku_helper/src/ui/home_screen.dart';
import 'package:sudoku_helper/src/ui/sudoku_grid.dart';

void main() {
  test(
    'digit focus follows selection and candidate input without changing notes',
    () {
      final game = GameController.fromPuzzle(
        SudokuBoard.parse(HomeScreen.samplePuzzle),
      );
      addTearDown(game.dispose);
      game.selectCell(0);
      expect(game.highlightedDigit, 5);
      game.selectCell(2);
      expect(game.highlightedDigit, isNull);
      game.toggleNoteMode();
      game.enterDigit(1);
      expect(game.highlightedDigit, 1);
      expect(game.hasSameValueAsSelected(12), isTrue);
      final notes = List<int>.of(game.manualCandidateMasks);
      game.moveSelection(rowDelta: 0, columnDelta: 1);
      expect(game.highlightedDigit, isNull);
      expect(game.manualCandidateMasks, notes);
      game.enterDigit(2);
      expect(game.highlightedDigit, 2);
      game.undo();
      expect(game.highlightedDigit, isNull);
      game.redo();
      game.enterDigit(3);
      game.clearSelected();
      expect(game.highlightedDigit, isNull);
      game.toggleNoteMode();
      game.enterDigit(6);
      expect(game.highlightedDigit, 6);
      game.togglePause();
      expect(game.highlightedDigit, isNull);
    },
  );

  for (final brightness in Brightness.values) {
    for (final automatic in [false, true]) {
      testWidgets(
        'candidate focus modes preserve marks and conflicts ($brightness, automatic=$automatic)',
        (tester) async {
          final game = GameController.fromPuzzle(
            SudokuBoard.parse(HomeScreen.samplePuzzle),
          );
          final settings = AppSettingsController(
            read: (_) => null,
            write: (_, _) {},
          );
          addTearDown(game.dispose);
          addTearDown(settings.dispose);
          settings.update(settings.value.copyWith(highlightPeers: false));
          game.selectCell(2);
          game.toggleNoteMode();
          game.enterDigit(5);
          game.enterDigit(1);
          if (automatic) game.showAllCandidates();
          game.selectCell(0);
          final notes = List<int>.of(game.manualCandidateMasks);
          final colors = ColorScheme.fromSeed(
            seedColor: const Color(0xFF596044),
            brightness: brightness,
          );
          await tester.pumpWidget(
            AppSettingsScope(
              controller: settings,
              child: MaterialApp(
                theme: ThemeData(colorScheme: colors),
                home: Scaffold(
                  body: Center(
                    child: SizedBox.square(
                      dimension: 360,
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
          Finder cell(int index) => find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label ==
                    '第 ${index ~/ 9 + 1} 行第 ${index % 9 + 1} 列${game.valueAt(index) == 0 ? '空格' : game.valueAt(index)}',
          );
          Text candidate(int index, int digit) => tester.widget<Text>(
            find.descendant(of: cell(index), matching: find.text('$digit')),
          );
          BoxDecoration cellDecoration(int index) =>
              tester
                      .widget<Container>(
                        find.descendant(
                          of: cell(index),
                          matching: find.byWidgetPredicate(
                            (widget) =>
                                widget is Container &&
                                widget.decoration is BoxDecoration &&
                                (widget.decoration! as BoxDecoration).shape ==
                                    BoxShape.rectangle &&
                                (widget.decoration! as BoxDecoration).border
                                    is Border,
                          ),
                        ),
                      )
                      .decoration!
                  as BoxDecoration;
          BoxDecoration? candidateDecoration(int index, int digit) =>
              tester
                      .widget<Container>(
                        find
                            .ancestor(
                              of: find.descendant(
                                of: cell(index),
                                matching: find.text('$digit'),
                              ),
                              matching: find.byType(Container),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration?;

          for (final mode in CandidateHighlightMode.values) {
            settings.update(
              settings.value.copyWith(candidateHighlightMode: mode),
            );
            await tester.pump();
            expect(candidate(2, 5).style?.color, colors.error);
            expect(candidate(2, 5).style?.decoration, isNull);
            expect(
              candidateDecoration(2, 5)?.border != null,
              mode != CandidateHighlightMode.off,
            );
            expect(candidateDecoration(2, 1), isNull);
            expect(
              cellDecoration(2).color,
              mode == CandidateHighlightMode.digitAndCell
                  ? colors.secondaryContainer
                  : colors.surface,
            );
            expect(cellDecoration(14).color, colors.secondaryContainer);
            expect(game.manualCandidateMasks, notes);
          }
          settings.update(settings.value.copyWith(highlightSameDigit: false));
          await tester.pump();
          expect(candidateDecoration(2, 5), isNull);
          expect(cellDecoration(2).color, colors.surface);
          expect(cellDecoration(14).color, colors.surface);

          settings.update(
            settings.value.copyWith(
              highlightSameDigit: true,
              candidateHighlightMode: CandidateHighlightMode.digitOnly,
            ),
          );
          game.selectCell(2);
          game.enterDigit(2);
          if (automatic) game.enterDigit(2);
          await tester.pump();
          expect(candidate(2, 2).style?.color, colors.onSecondaryContainer);
          expect(candidate(2, 2).style?.fontWeight, FontWeight.w800);
          expect(candidateDecoration(2, 2)?.border, isNotNull);
          expect(candidateDecoration(2, 5), isNull);
          game.selectCell(3);
          await tester.pump();
          expect(candidateDecoration(2, 2), isNull);

          if (automatic) {
            final index = List.generate(81, (index) => index).firstWhere(
              (index) =>
                  game.valueAt(index) == 0 &&
                  (game.legalMaskAt(index) & SudokuEngine.bitFor(5)) != 0,
            );
            game.selectCell(index);
            game.enterDigit(5); // Exclude an automatic candidate.
            game.selectCell(0);
            settings.update(
              settings.value.copyWith(
                candidateHighlightMode: CandidateHighlightMode.digitAndCell,
              ),
            );
            await tester.pump();
            expect(
              find.descendant(of: cell(index), matching: find.text('5')),
              findsNothing,
            );
            expect(cellDecoration(index).color, colors.surface);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
