import 'package:flutter/material.dart';

import '../controller/game_controller.dart';
import '../logic/logical_solver.dart';
import '../logic/practice_puzzles.dart';
import '../model/sudoku_board.dart';
import '../persistence/practice_progress_repository.dart';
import '../settings/app_settings.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    this.progress = const PracticeProgressRepository(),
  });
  final PracticeProgressRepository progress;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _search = TextEditingController();
  late Set<String> _completed;
  PracticeCategory? _category;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _completed = widget.progress.load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openLesson(PracticePuzzle lesson) async {
    try {
      final controller = GameController.practice(
        SudokuBoard.parse(lesson.puzzle),
        lesson.technique,
        initialEliminations: lesson.initialEliminations,
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(
            controller: controller,
            title: '技巧练习 · ${lesson.technique.label}',
            saveProgress: false,
            practiceSummary: lesson.summary,
            onPracticeCompleted: () => widget.progress.markCompleted(lesson.id),
          ),
        ),
      );
      if (mounted) setState(() => _completed = widget.progress.load());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('这道练习暂时无法加载，请选择其他技巧。')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lessons = practicePuzzles
        .where(
          (lesson) =>
              (_category == null || lesson.category == _category) &&
              ('${lesson.technique.label} ${lesson.summary} ${lesson.technique.difficulty.label}')
                  .toLowerCase()
                  .contains(_query.trim().toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('技巧练习'),
        actions: [
          if (AppSettingsScope.maybeOf(context) != null)
            IconButton(
              tooltip: '设置',
              icon: const Icon(Icons.tune),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                '一次练习，一个结构',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '先观察，再看解释，最后执行一步。练习不会覆盖正常解题进度。',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Text(
                '已练习 ${_completed.length} / ${practicePuzzles.length} 种技巧',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _completed.length / practicePuzzles.length,
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
                backgroundColor: colors.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: '搜索技巧，如 X-Wing、链、ALS',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清空搜索',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('全部'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  for (final category in PracticeCategory.values)
                    ChoiceChip(
                      label: Text(category.label),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                ],
              ),
              if (lessons.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    '没有找到匹配的技巧，试试其他关键词或分类。',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final category in PracticeCategory.values)
                if (lessons.any((lesson) => lesson.category == category)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 12),
                    child: Text(
                      category.label,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  for (final lesson in lessons.where(
                    (lesson) => lesson.category == category,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            lesson.technique.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lesson.summary),
                                const SizedBox(height: 8),
                                Text(
                                  '${lesson.technique.difficulty.label}${_completed.contains(lesson.id) ? ' · 已练习' : ''}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Icon(
                            _completed.contains(lesson.id)
                                ? Icons.check_circle_outline
                                : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                          onTap: () => _openLesson(lesson),
                        ),
                      ),
                    ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
