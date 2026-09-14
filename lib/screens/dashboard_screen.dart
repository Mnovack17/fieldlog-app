import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  final List<FieldEntry> entries;
  const DashboardScreen({super.key, required this.entries});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _filter = 'all';

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final todays = entries.where((e) => e.date == _today).toList();
    final behindToday = todays.where((e) => e.status == 'behind').length;
    final followupOpen = entries.where((e) => e.followUp).length;
    final safetyToday = todays.where((e) => e.severity == 'high_safety').length;

    final breakdown = <String, int>{'on_track': 0, 'ahead': 0, 'behind': 0, 'complete': 0};
    for (final e in entries) {
      if (breakdown.containsKey(e.status)) breakdown[e.status] = breakdown[e.status]! + 1;
    }

    List<FieldEntry> filtered = entries;
    switch (_filter) {
      case 'today':
        filtered = todays;
        break;
      case 'followup':
        filtered = entries.where((e) => e.followUp).toList();
        break;
      case 'safety':
        filtered = entries.where((e) => e.severity == 'high_safety').toList();
        break;
      case 'behind':
        filtered = entries.where((e) => e.status == 'behind').toList();
        break;
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Today's Snapshot", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text(DateFormat('EEE, MMM d').format(DateTime.now()), style: const TextStyle(color: AppColors.inkMuted, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _statTile('Entries Today', todays.length.toString(), AppColors.ink),
              _statTile('Behind Schedule', behindToday.toString(), AppColors.warn),
              _statTile('Follow-ups Open', followupOpen.toString(), AppColors.crit),
              _statTile('High-Safety Issues', safetyToday.toString(), AppColors.crit),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: breakdown.entries.map((e) {
              return _breakdownChip(e.key, e.value);
            }).toList(),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'All entries'),
                _filterChip('today', 'Today'),
                _filterChip('followup', 'Needs follow-up'),
                _filterChip('safety', 'High safety'),
                _filterChip('behind', 'Behind schedule'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 18),
                child: Column(
                  children: [
                    Text(
                      entries.isEmpty ? 'No entries yet' : 'Nothing matches this filter',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entries.isEmpty
                          ? 'Submitted updates will show up here as soon as a crew logs one.'
                          : 'Try a different filter above.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map(_entryCard),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color valueColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkMuted, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _breakdownChip(String status, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor(status), shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(statusLabel(status), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.inkSecondary)),
          const SizedBox(width: 5),
          Text(count.toString(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final on = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        onSelected: (_) => setState(() => _filter = key),
        selectedColor: AppColors.ink,
        labelStyle: TextStyle(color: on ? Colors.white : AppColors.inkSecondary, fontWeight: FontWeight.w600, fontSize: 12.5),
        backgroundColor: AppColors.surface,
        side: BorderSide(color: on ? AppColors.ink : AppColors.border),
      ),
    );
  }

  Widget _entryCard(FieldEntry e) {
    Color stripe = AppColors.border;
    if (e.severity == 'high_safety') {
      stripe = AppColors.crit;
    } else if (e.status == 'behind') {
      stripe = AppColors.warn;
    } else if (e.status == 'complete') {
      stripe = AppColors.good;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, decoration: BoxDecoration(color: stripe, borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                              children: [
                                TextSpan(text: e.team),
                                TextSpan(text: '  —  ${e.site}', style: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.inkMuted)),
                              ],
                            ),
                          ),
                        ),
                        Text(_fmtDate(e.date), style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tag(statusLabel(e.status), statusSoft(e.status), statusColor(e.status)),
                        if (e.duration.isNotEmpty) _tag(e.duration, AppColors.surfaceSunk, AppColors.inkSecondary),
                        if (e.followUp) _tag('Follow-up: ${e.followUpOwner.isEmpty ? "unassigned" : e.followUpOwner}', AppColors.critSoft, AppColors.crit),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(e.tasks, style: const TextStyle(fontSize: 13.5, color: AppColors.ink, height: 1.4)),
                    if (e.hasIssue && e.issueText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: e.severity == 'high_safety' ? AppColors.critSoft : AppColors.warnSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: e.severity == 'high_safety' ? AppColors.crit : AppColors.warn,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(text: '${severityLabel(e.severity)}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                              TextSpan(text: e.issueText),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Supervisor: ${e.supervisor.isEmpty ? "—" : e.supervisor}', style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                        if (e.notes.isNotEmpty)
                          Flexible(
                            child: Text('Note: ${e.notes}', style: const TextStyle(fontSize: 12, color: AppColors.inkMuted), overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  String _fmtDate(String iso) {
    try {
      final d = DateFormat('yyyy-MM-dd').parse(iso);
      return DateFormat('MMM d').format(d);
    } catch (_) {
      return iso;
    }
  }
}
