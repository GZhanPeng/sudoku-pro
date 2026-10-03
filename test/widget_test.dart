import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_helper/main.dart';
import 'package:sudoku_helper/src/ui/game_screen.dart';

void main() {
  testWidgets('home screen exposes all entry paths', (tester) async {
    await tester.pumpWidget(const SudokuHelperApp());

    expect(find.text('数独助手'), findsOneWidget);
    expect(find.text('自动生成新题'), findsOneWidget);
    expect(find.text('拍照导入并校对'), findsOneWidget);
    expect(find.text('手动录入题目'), findsOneWidget);
    expect(find.text('打开示例盘面'), findsOneWidget);
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

  testWidgets('new puzzle offers four human-logic difficulty levels', (
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
  });
}
