import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Daily cleanliness checklist. The admin ticks steps; customers see the
/// same list read-only, plus the last two weeks at a glance.
class HygieneScreen extends StatelessWidget {
  final bool editable;
  const HygieneScreen({super.key, required this.editable});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final today = dateOnly(DateTime.now());
    final log = editable ? store.hygieneToday() : store.hygieneOn(today);
    final done = log?.done ?? const <String>[];
    final days = [
      for (var i = 13; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final total = hygieneItems.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Hygiene')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fmtDay(today),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  done.length == total
                      ? 'Spotless today ✨'
                      : '${done.length} of $total steps done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: done.length / total,
                    minHeight: 10,
                    color: AppColors.leaf,
                    backgroundColor: Colors.white24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '🔥 ${store.hygieneStreak}-day clean streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(
            editable
                ? 'Tick each step as you finish it'
                : 'What the farm did today',
          ),
          Card(
            child: Column(
              children: [
                for (final (i, item) in hygieneItems.indexed) ...[
                  if (i > 0) const Divider(indent: 70),
                  _StepTile(
                    item: item,
                    done: done.contains(item.key),
                    onTap: editable
                        ? () => store.toggleHygiene(item.key)
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const SectionHeader('Last 14 days'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (final d in days)
                        _DayDot(day: d, log: store.hygieneOn(d)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legend(AppColors.green, 'All done'),
                      const SizedBox(width: 14),
                      _legend(AppColors.amber, 'Partly'),
                      const SizedBox(width: 14),
                      _legend(Colors.grey, 'Not logged'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!editable) ...[
            const SizedBox(height: 16),
            Text(
              'The farm updates this checklist every morning and evening so you always know your milk was handled cleanly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legend(Color c, String t) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(t, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class _StepTile extends StatelessWidget {
  final HygieneItem item;
  final bool done;
  final VoidCallback? onTap;
  const _StepTile({required this.item, required this.done, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done
              ? AppColors.green.withValues(alpha: 0.14)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: done ? null : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
        child: done
            ? const Icon(
                Icons.check_circle,
                color: AppColors.green,
                key: ValueKey(1),
                size: 28,
              )
            : Icon(
                Icons.radio_button_unchecked,
                key: const ValueKey(0),
                size: 28,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final DateTime day;
  final HygieneLog? log;
  const _DayDot({required this.day, this.log});

  @override
  Widget build(BuildContext context) {
    final color = log == null || log!.score == 0
        ? Colors.grey
        : log!.complete
        ? AppColors.green
        : AppColors.amber;
    return Tooltip(
      message:
          '${fmtShortDate(day)}: ${log?.score ?? 0}/${hygieneItems.length}',
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: log == null ? 0.12 : 0.2),
          borderRadius: BorderRadius.circular(10),
          border: sameDay(day, DateTime.now())
              ? Border.all(color: color, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color == Colors.grey ? null : color,
          ),
        ),
      ),
    );
  }
}
