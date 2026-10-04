import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_helper/main.dart';
import 'package:sudoku_helper/src/controller/game_controller.dart';
import 'package:sudoku_helper/src/logic/logical_solver.dart';
import 'package:sudoku_helper/src/model/sudoku_board.dart';
import 'package:sudoku_helper/src/ui/game_screen.dart';

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

    expect(find.text('X-Wing'), findsOneWidget);
    expect(find.text('空矩形'), findsOneWidget);
    expect(find.text('W-Wing'), findsOneWidget);

    await tester.tap(find.text('X-Wing'));
    await tester.pumpAndSettle();

    expect(find.text('技巧练习 · X-Wing'), findsOneWidget);
    expect(find.textContaining('练习已就绪'), findsOneWidget);
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
