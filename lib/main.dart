import 'package:flutter/material.dart';

import 'src/ui/home_screen.dart';
import 'src/settings/app_settings.dart';

void main() {
  runApp(const SudokuHelperApp());
}

class SudokuHelperApp extends StatefulWidget {
  const SudokuHelperApp({super.key, this.settings});

  final AppSettingsController? settings;

  @override
  State<SudokuHelperApp> createState() => _SudokuHelperAppState();
}

class _SudokuHelperAppState extends State<SudokuHelperApp> {
  late final AppSettingsController _settings =
      widget.settings ?? AppSettingsController();

  @override
  void dispose() {
    if (widget.settings == null) _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF535D4E);
    return AppSettingsScope(
      controller: _settings,
      child: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) => MaterialApp(
          title: '数独助手',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(
                  seedColor: seed,
                  brightness: Brightness.light,
                ).copyWith(
                  primary: seed,
                  primaryContainer: const Color(0xFFE7E9E2),
                  onPrimaryContainer: const Color(0xFF262D23),
                  secondary: const Color(0xFF5D6259),
                  secondaryContainer: const Color(0xFFEAEAE4),
                  tertiary: const Color(0xFF536067),
                  tertiaryContainer: const Color(0xFFE6EAEB),
                  onTertiaryContainer: const Color(0xFF253239),
                  surface: const Color(0xFFFFFEF9),
                  surfaceContainerLow: const Color(0xFFF8F6F0),
                  surfaceContainerHighest: const Color(0xFFECEAE3),
                  outline: const Color(0xFF85877F),
                  outlineVariant: const Color(0xFFD9D7CE),
                ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F3ED),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF5F3ED),
              surfaceTintColor: Colors.transparent,
            ),
            dividerTheme: const DividerThemeData(space: 1),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            segmentedButtonTheme: SegmentedButtonThemeData(
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            segmentedButtonTheme: SegmentedButtonThemeData(
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          themeMode: _settings.value.themeMode,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
