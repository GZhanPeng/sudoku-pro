import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../logic/logical_solver.dart';
import '../settings/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppSettingsScope.maybeOf(context)!;
    final preferences = controller.value;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                '按你的习惯解题',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                kIsWeb ? '设置自动保存在当前浏览器，修改立即生效。' : '修改立即生效。',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const _SectionLabel('外观'),
              _SettingsCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('显示模式'),
                        const SizedBox(height: 12),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('跟随系统'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('浅色'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('深色'),
                            ),
                          ],
                          selected: {preferences.themeMode},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) => controller.update(
                            preferences.copyWith(themeMode: selection.first),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('候选字号'),
                        const SizedBox(height: 12),
                        SegmentedButton<CandidateSize>(
                          segments: [
                            for (final size in CandidateSize.values)
                              ButtonSegment(
                                value: size,
                                label: Text(size.label),
                              ),
                          ],
                          selected: {preferences.candidateSize},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) => controller.update(
                            preferences.copyWith(
                              candidateSize: selection.first,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const _SectionLabel('棋盘辅助'),
              _SettingsCard(
                children: [
                  SwitchListTile(
                    title: const Text('高亮同行、同列与同宫'),
                    subtitle: const Text('选中格周围的相关区域淡淡着色'),
                    value: preferences.highlightPeers,
                    onChanged: (value) => controller.update(
                      preferences.copyWith(highlightPeers: value),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('高亮相同数字'),
                    subtitle: const Text('点击已填数字，或在候选模式下输入数字时追踪同数'),
                    value: preferences.highlightSameDigit,
                    onChanged: (value) => controller.update(
                      preferences.copyWith(highlightSameDigit: value),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: DropdownButtonFormField<CandidateHighlightMode>(
                      key: ValueKey(preferences.candidateHighlightMode),
                      initialValue: preferences.candidateHighlightMode,
                      decoration: const InputDecoration(labelText: '同数候选高亮方式'),
                      items: [
                        for (final mode in CandidateHighlightMode.values)
                          DropdownMenuItem(
                            value: mode,
                            child: Text(mode.label),
                          ),
                      ],
                      onChanged: preferences.highlightSameDigit
                          ? (mode) {
                              if (mode != null) {
                                controller.update(
                                  preferences.copyWith(
                                    candidateHighlightMode: mode,
                                  ),
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('候选冲突提醒'),
                    subtitle: const Text('与行、列、宫中已填数字重复的候选标红'),
                    value: preferences.warnCandidateConflicts,
                    onChanged: (value) => controller.update(
                      preferences.copyWith(warnCandidateConflicts: value),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('显示解题用时'),
                    subtitle: const Text('关闭后仍会计时，暂停按钮保持可用'),
                    value: preferences.showTimer,
                    onChanged: (value) => controller.update(
                      preferences.copyWith(showTimer: value),
                    ),
                  ),
                ],
              ),
              const _SectionLabel('开始新题'),
              _SettingsCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<PuzzleDifficulty>(
                      key: ValueKey(preferences.defaultDifficulty),
                      initialValue: preferences.defaultDifficulty,
                      decoration: const InputDecoration(labelText: '偏好难度'),
                      items: [
                        for (final difficulty in PuzzleDifficulty.values)
                          DropdownMenuItem(
                            value: difficulty,
                            child: Text(difficulty.label),
                          ),
                      ],
                      onChanged: (difficulty) {
                        if (difficulty != null) {
                          controller.update(
                            preferences.copyWith(defaultDifficulty: difficulty),
                          );
                        }
                      },
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('新题自动全标候选'),
                    subtitle: const Text('仅用于新开的普通题，保留已有进度与练习设置'),
                    value: preferences.autoCandidates,
                    onChanged: (value) => controller.update(
                      preferences.copyWith(autoCandidates: value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final reset = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('恢复默认设置？'),
                      content: const Text('外观和解题偏好会恢复默认，当前题目和候选不会被清除。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('恢复'),
                        ),
                      ],
                    ),
                  );
                  if (reset == true && context.mounted) controller.reset();
                },
                icon: const Icon(Icons.restore),
                label: const Text('恢复默认设置'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 28, 0, 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}
