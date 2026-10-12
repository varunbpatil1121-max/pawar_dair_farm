import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'cattle_screen.dart';

class VaccinationsScreen extends StatelessWidget {
  const VaccinationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final pending = store.upcomingVaccinations;
    final overdue = pending.where((v) => v.isOverdue).toList();
    final week = pending
        .where((v) => !v.isOverdue && v.daysUntilDue <= 7)
        .toList();
    final later = pending.where((v) => v.daysUntilDue > 7).toList();
    final done =
        store.vaccinations
            .where((v) => v.isDone && store.cowById(v.cowId) != null)
            .toList()
          ..sort((a, b) => b.doneDate!.compareTo(a.doneDate!));

    Widget group(String title, Color color, List items) => items.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$title (${items.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  children: [for (final v in items) VaccinationTile(v: v)],
                ),
              ),
            ],
          );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vaccinations'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => showVaccinationSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Schedule'),
        ),
        body: TabBarView(
          children: [
            pending.isEmpty
                ? const EmptyState(
                    icon: Icons.verified_outlined,
                    title: 'All vaccinations done 🎉',
                    message: 'Schedule the next round with the button below',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    children: [
                      group('Overdue', AppColors.rose, overdue),
                      group('Due this week', AppColors.amber, week),
                      group('Later', AppColors.sky, later),
                    ],
                  ),
            done.isEmpty
                ? const EmptyState(icon: Icons.history, title: 'No history yet')
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      Card(
                        child: Column(
                          children: [
                            for (final v in done) VaccinationTile(v: v),
                          ],
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
