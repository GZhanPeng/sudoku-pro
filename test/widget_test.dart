import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_helper/main.dart';
import 'package:sudoku_helper/src/controller/game_controller.dart';
import 'package:sudoku_helper/src/logic/logical_solver.dart';
import 'package:sudoku_helper/src/model/sudoku_board.dart';
import 'package:sudoku_helper/src/ui/game_screen.dart';
import 'package:sudoku_helper/src/ui/home_screen.dart';
import 'package:sudoku_helper/src/ui/sudoku_grid.dart';

const _xyChainPuzzle =
    '700060009'
    '000900500'
    '000050040'
    '090200006'
    '075000300'
    '004003020'
    '060010000'
    '007004000'
    '300020064';

const _groupedAicPuzzle =
    '345128900'
    '976000281'
    '281000345'
    '000000010'
    '100600030'
    '402081509'
    '704000128'
    '819040653'
    '023810794';

const _oneCellPuzzle =
    '034678912'
    '672195348'
    '198342567'
    '859761423'
    '426853791'
    '713924856'
    '961537284'
    '287419635'
    '345286179';

void main() {
  testWidgets('home screen exposes all entry paths', (tester) async {
    await tester.pumpWidget(const SudokuHelperApp());

    expect(find.text('数独助手'), findsOneWidget);
    expect(find.text('自动生成新题'), findsOneWidget);
    expect(find.text('技巧练习'), findsOneWidget);
    expect(find.text('拍照导入并校对'), findsOneWidget);
    expect(find.text('手动录入题目'), findsOneWidget);
    expect(find.text('打开示例盘面'), findsOneWidget);
  });

  testWidgets('practice catalog opens a prepared technique lesson', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SudokuHelperApp());
    await tester.tap(find.text('技巧练习'));
    await tester.pumpAndSettle();

    expect(find.text('一次练习，一个结构'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '鱼与翼'));
    await tester.pumpAndSettle();
    expect(find.text('X-Wing'), findsOneWidget);

    await tester.ensureVisible(find.text('X-Wing'));
    await tester.tap(find.text('X-Wing'));
    await tester.pumpAndSettle();

    expect(find.text('技巧练习 · X-Wing'), findsOneWidget);
    expect(find.textContaining('练习已就绪'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('提示'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('提示'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home and game screens fit a phone-sized viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SudokuHelperApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('打开示例盘面'));
    await tester.pumpAndSettle();

    expect(find.text('经典 9×9'), findsOneWidget);
    expect(find.text('基础清扫'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hint is revealed in two stages on the sample puzzle', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SudokuHelperApp());
    await tester.tap(find.text('打开示例盘面'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('提示'));
    await tester.pump();
    expect(find.text('先看哪里'), findsOneWidget);

    await tester.tap(find.text('说明结构'));
    await tester.pump();
    expect(find.text('执行这一步'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('game accepts a conflicting trial from the number pad', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SudokuHelperApp());
    await tester.tap(find.text('打开示例盘面'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('第 1 行第 3 列空格'));
    await tester.tap(find.widgetWithText(FilledButton, '5'));
    await tester.pump();

    final gameScreen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(gameScreen.controller.valueAt(2), 5);
    expect(gameScreen.controller.isConflictingCell(2), isTrue);
    expect(find.textContaining('数字重复'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual candidates and full candidates are distinct controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SudokuHelperApp());
    await tester.tap(find.text('打开示例盘面'));
    await tester.pumpAndSettle();

    expect(find.text('填数字'), findsOneWidget);
    expect(find.text('手动候选'), findsOneWidget);
    expect(find.text('全标'), findsOneWidget);

    await tester.tap(find.text('手动候选'));
    await tester.pump();

    final gameScreen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(gameScreen.controller.noteMode, isTrue);
    expect(gameScreen.controller.candidatesVisible, isFalse);
    expect(find.textContaining('全标是另一项自动操作'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    for (final fullCandidates in [false, true]) {
      testWidgets(
        'candidate conflicts update with board edits (${brightness.name}, full=$fullCandidates)',
        (tester) async {
          final controller = GameController.fromPuzzle(
            SudokuBoard.parse(HomeScreen.samplePuzzle),
          );
          addTearDown(controller.dispose);
          controller.selectCell(2);
          controller.toggleNoteMode();
          // 5 conflicts with the row, 8 with the column, and 6 only with the box.
          // 1 is locally legal even though the solution for this cell is 4.
          for (final digit in [1, 5, 6, 8]) {
            controller.enterDigit(digit);
          }
          if (fullCandidates) controller.showAllCandidates();

          final colors = ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D6B63),
            brightness: brightness,
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(colorScheme: colors),
              home: Scaffold(
                body: Center(
                  child: SizedBox.square(
                    dimension: 360,
                    child: AnimatedBuilder(
                      animation: controller,
                      builder: (_, _) => SudokuGrid(controller: controller),
                    ),
                  ),
                ),
              ),
            ),
          );

          Text candidate(int digit) => tester.widget<Text>(
            find.descendant(
              of: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label == '第 1 行第 3 列空格',
              ),
              matching: find.text('$digit'),
            ),
          );

          for (final digit in [5, 6, 8]) {
            expect(candidate(digit).style?.color, colors.error);
            expect(candidate(digit).style?.decoration, isNull);
          }
          expect(candidate(1).style?.color, colors.onSurfaceVariant);

          controller.toggleNoteMode();
          controller.selectCell(3);
          controller.enterDigit(1);
          await tester.pump();
          expect(candidate(1).style?.color, colors.error);

          controller.undo();
          await tester.pump();
          expect(candidate(1).style?.color, colors.onSurfaceVariant);

          controller.enterDigit(1);
          await tester.pump();
          expect(candidate(1).style?.color, colors.error);
          controller.clearSelected();
          await tester.pump();
          expect(candidate(1).style?.color, colors.onSurfaceVariant);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('desktop game uses a board and side-panel layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SudokuHelperApp());
    await tester.tap(find.text('打开示例盘面'));
    await tester.pumpAndSettle();

    final boardCenter = tester.getCenter(find.byType(SudokuGrid));
    final controlsCenter = tester.getCenter(find.text('输入方式'));
    expect(boardCenter.dx, lessThan(controlsCenter.dx));
    expect(find.text('基础清扫'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop keyboard controls input, movement, and note mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = GameController.fromPuzzle(
      SudokuBoard.parse(
        '530070000'
        '600195000'
        '098000060'
        '800060003'
        '400803001'
        '700020006'
        '060000280'
        '000419005'
        '000080079',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(controller: controller, saveProgress: false),
      ),
    );

    controller.selectCell(2);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5, character: '5');
    await tester.pump();
    expect(controller.valueAt(2), 5);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.selectedIndex, 3);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyN, character: 'n');
    await tester.pump();
    expect(controller.noteMode, isTrue);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pause hides the board and can resume the timer', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SudokuHelperApp());
    await tester.tap(find.text('打开示例盘面'));
    await tester.pumpAndSettle();

    final gameScreen = tester.widget<GameScreen>(find.byType(GameScreen));
    await tester.tap(find.byTooltip('暂停计时'));
    await tester.pump();

    expect(gameScreen.controller.isPaused, isTrue);
    expect(find.text('已暂停'), findsOneWidget);
    expect(find.text('盘面已隐藏，计时已停止'), findsOneWidget);

    await tester.tap(find.text('继续游戏'));
    await tester.pump();
    expect(gameScreen.controller.isPaused, isFalse);
    expect(find.byTooltip('暂停计时'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finishing a puzzle shows elapsed and assistance statistics', (
    tester,
  ) async {
    final controller = GameController.resume(
      puzzle: SudokuBoard.parse(_oneCellPuzzle),
      values: SudokuBoard.parse(_oneCellPuzzle).values.toList(),
      excludedMasks: List<int>.filled(81, 0),
      candidatesVisible: false,
      assistedCells: <int>{},
      elapsedSeconds: 125,
      hintUseCount: 2,
      basicSweepUseCount: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(controller: controller, saveProgress: false),
      ),
    );

    controller.selectCell(0);
    controller.enterDigit(5);
    await tester.pumpAndSettle();

    expect(find.text('完成了！'), findsNWidgets(2));
    expect(find.text('02:05'), findsNWidgets(2));
    expect(find.text('2 次'), findsOneWidget);
    expect(find.text('1 次'), findsOneWidget);
    expect(find.text('查看完成盘面'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('chain hint numbers its nodes and coordinate chips focus cells', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = GameController.practice(
      SudokuBoard.parse(_xyChainPuzzle),
      LogicalTechnique.xyChain,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          controller: controller,
          title: 'XY-Chain 可视化测试',
          saveProgress: false,
        ),
      ),
    );

    await tester.tap(find.text('提示'));
    await tester.pump();
    await tester.tap(find.text('说明结构'));
    await tester.pump();

    final step = controller.hintStep!;
    final first = step.chainNodes.first;
    final firstChip = find.byKey(
      ValueKey('hint-node-0-${first.index}-${first.digit}'),
    );
    expect(firstChip, findsOneWidget);
    expect(find.textContaining('① 链头'), findsOneWidget);
    expect(find.textContaining('链尾'), findsOneWidget);

    await tester.ensureVisible(firstChip);
    await tester.tap(firstChip);
    await tester.pump();
    expect(controller.selectedIndex, first.index);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('grouped AIC numbers multi-cell nodes and focuses them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = GameController.practice(
      SudokuBoard.parse(_groupedAicPuzzle),
      LogicalTechnique.groupedAic,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          controller: controller,
          title: 'Grouped AIC 可视化测试',
          saveProgress: false,
        ),
      ),
    );

    await tester.tap(find.text('提示'));
    await tester.pump();
    await tester.tap(find.text('说明结构'));
    await tester.pump();

    final step = controller.hintStep!;
    final groupIndex = step.chainGroups.indexWhere((group) => group.length > 1);
    final group = step.chainGroups[groupIndex];
    final groupChip = find.byKey(
      ValueKey(
        'hint-group-$groupIndex-${group.first.index}-${group.first.digit}',
      ),
    );
    expect(groupChip, findsOneWidget);
    expect(find.textContaining(' 组'), findsWidgets);

    await tester.ensureVisible(groupChip);
    await tester.tap(groupChip);
    await tester.pump();
    expect(controller.selectedIndex, group.first.index);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('new puzzle offers six human-logic difficulty levels', (
    tester,
  ) async {
    await tester.pumpWidget(const SudokuHelperApp());
    await tester.tap(find.text('自动生成新题'));
    await tester.pumpAndSettle();

    expect(find.text('选择难度'), findsOneWidget);
    expect(find.text('入门'), findsOneWidget);
    expect(find.text('简单'), findsOneWidget);
    expect(find.text('中等'), findsOneWidget);
    expect(find.text('困难'), findsOneWidget);
    expect(find.text('专家'), findsOneWidget);
    expect(find.text('骨灰'), findsOneWidget);
  });
}
