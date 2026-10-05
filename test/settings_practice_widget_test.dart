import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_helper/main.dart';
import 'package:sudoku_helper/src/controller/game_controller.dart';
import 'package:sudoku_helper/src/logic/logical_solver.dart';
import 'package:sudoku_helper/src/logic/practice_puzzles.dart';
import 'package:sudoku_helper/src/model/sudoku_board.dart';
import 'package:sudoku_helper/src/persistence/practice_progress_repository.dart';
import 'package:sudoku_helper/src/settings/app_settings.dart';
import 'package:sudoku_helper/src/ui/game_screen.dart';
import 'package:sudoku_helper/src/ui/home_screen.dart';
import 'package:sudoku_helper/src/ui/practice_screen.dart';
import 'package:sudoku_helper/src/ui/settings_screen.dart';
import 'package:sudoku_helper/src/ui/sudoku_grid.dart';

void main() {
  testWidgets(
    'whole board stays visible when browser width and height change',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = GameController.fromPuzzle(
        SudokuBoard.parse(HomeScreen.samplePuzzle),
      );
      game.showAllCandidates();
      await tester.pumpWidget(
        MaterialApp(home: GameScreen(controller: game, saveProgress: false)),
      );
      final boardSizes = <Size>[];
      for (final viewport in const [
        Size(1280, 720),
        Size(1280, 540),
        Size(1024, 600),
        Size(1440, 900),
        Size(800, 600),
        Size(640, 480),
        Size(390, 844),
      ]) {
        tester.view.physicalSize = viewport;
        await tester.pumpAndSettle();
        final board = tester.getRect(find.byType(SudokuGrid));
        expect(board.width, closeTo(board.height, 0.01));
        expect(board.left, greaterThanOrEqualTo(0));
        expect(board.right, lessThanOrEqualTo(viewport.width));
        expect(board.top, greaterThanOrEqualTo(kToolbarHeight));
        expect(board.bottom, lessThanOrEqualTo(viewport.height));
        final lastCell = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == '第 9 行第 9 列9',
        );
        expect(lastCell.hitTestable(), findsOneWidget);
        await tester.tap(lastCell);
        await tester.pump();
        expect(game.selectedIndex, 80);
        expect(tester.takeException(), isNull, reason: '$viewport');
        boardSizes.add(board.size);
      }
      expect(boardSizes[1].height, lessThan(boardSizes[0].height));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('desktop hint panel scrolls without moving the board', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final lesson = practicePuzzles.firstWhere(
      (lesson) => lesson.technique == LogicalTechnique.alsXZ,
    );
    final controller = GameController.practice(
      SudokuBoard.parse(lesson.puzzle),
      lesson.technique,
      initialEliminations: lesson.initialEliminations,
    );
    controller.requestHint();
    controller.revealHintExplanation();
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          controller: controller,
          saveProgress: false,
          practiceSummary: lesson.summary,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boardBefore = tester.getRect(find.byType(SudokuGrid));
    expect(boardBefore.bottom, lessThanOrEqualTo(720));
    await tester.ensureVisible(find.text('执行这一步'));
    await tester.pumpAndSettle();
    expect(find.text('执行这一步').hitTestable(), findsOneWidget);
    expect(tester.getRect(find.byType(SudokuGrid)), boardBefore);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings apply to an existing game without changing its marks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = <String, String>{};
    final settings = AppSettingsController(
      read: (key) => storage[key],
      write: (key, value) => storage[key] = value,
    );
    addTearDown(settings.dispose);
    await tester.pumpWidget(SudokuHelperApp(settings: settings));
    await tester.ensureVisible(find.text('打开示例盘面'));
    await tester.tap(find.text('打开示例盘面'));
    await tester.pumpAndSettle();
    final game = tester.widget<GameScreen>(find.byType(GameScreen)).controller;
    game.selectCell(2);
    game.toggleNoteMode();
    game.enterDigit(5);
    await tester.pump();
    final marks = List<int>.of(game.manualCandidateMasks);
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('较大'));
    await tester.pumpAndSettle();
    expect(find.text('同数候选高亮方式'), findsNothing);
    await tester.scrollUntilVisible(find.text('候选冲突提醒'), 180);
    await tester.tap(find.widgetWithText(SwitchListTile, '候选冲突提醒'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('显示解题用时'), 150);
    await tester.tap(find.widgetWithText(SwitchListTile, '显示解题用时'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(game.manualCandidateMasks, marks);
    final candidate = tester.widget<Text>(
      find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == '第 1 行第 3 列空格',
        ),
        matching: find.text('5'),
      ),
    );
    final colors = Theme.of(tester.element(find.byType(GameScreen)))
        .colorScheme;
    expect(candidate.style?.color, colors.onSecondaryContainer);
    expect(candidate.style?.fontSize, 10.5);
    expect(find.byIcon(Icons.timer_outlined), findsNothing);
    expect(find.byTooltip('暂停计时'), findsOneWidget);
    expect(storage[AppSettingsController.storageKey], isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('new-game preference enables automatic candidates', (
    tester,
  ) async {
    final settings = AppSettingsController();
    addTearDown(settings.dispose);
    settings.update(settings.value.copyWith(autoCandidates: true));
    await tester.pumpWidget(SudokuHelperApp(settings: settings));
    await tester.ensureVisible(find.text('打开示例盘面'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开示例盘面'));
    await tester.pumpAndSettle();
    final game = tester.widget<GameScreen>(find.byType(GameScreen)).controller;
    expect(game.candidatesVisible, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('practice search opens ALS and records only an executed target', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = <String, String>{};
    final progress = PracticeProgressRepository(
      read: (key) => storage[key],
      write: (key, value) => storage[key] = value,
    );
    await tester.pumpWidget(
      MaterialApp(home: PracticeScreen(progress: progress)),
    );
    await tester.enterText(find.byType(TextField), 'ALS-XZ');
    await tester.pumpAndSettle();
    expect(find.text('X-Wing'), findsNothing);
    final alsLesson = find.widgetWithText(ListTile, 'ALS-XZ');
    expect(alsLesson, findsOneWidget);
    expect(find.text('双链 ALS-XZ'), findsOneWidget);
    await tester.ensureVisible(alsLesson);
    await tester.tap(alsLesson);
    await tester.pumpAndSettle();
    expect(find.text('技巧练习 · ALS-XZ'), findsOneWidget);
    expect(progress.load(), isEmpty);
    await tester.scrollUntilVisible(
      find.text('提示'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('提示'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('说明结构'));
    await tester.tap(find.text('说明结构'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('执行这一步'));
    await tester.tap(find.text('执行这一步'));
    await tester.pumpAndSettle();
    expect(progress.load(), {'alsXZ'});
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('已练习 1 / 21 种技巧'), findsOneWidget);
    expect(storage.keys, [PracticeProgressRepository.storageKey]);
    await tester.enterText(find.byType(TextField), '无此技巧');
    await tester.pumpAndSettle();
    expect(find.textContaining('没有找到匹配'), findsOneWidget);
    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
