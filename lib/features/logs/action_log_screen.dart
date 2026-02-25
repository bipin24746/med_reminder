import 'package:flutter/material.dart';
import '../../services/action_log_service.dart';

class ActionLogScreen extends StatefulWidget {
  const ActionLogScreen({super.key});

  @override
  State<ActionLogScreen> createState() => _ActionLogScreenState();
}

class _ActionLogScreenState extends State<ActionLogScreen> {
  bool _loading = true;
  String? _error;

  /// Final rows to show (grouped)
  List<_LogRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final events = await ActionLogService.fetch();
      final rows = _buildRows(events);

      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Build a simplified list:
  /// group by scheduledAt -> keep TAKEN or SKIP_NOW
  List<_LogRow> _buildRows(List<ActionLogEvent> events) {
    // group by scheduledAt
    final Map<int, List<ActionLogEvent>> byScheduledAt = {};

    for (final e in events) {
      // If scheduledAt missing, fallback to ts (still show something)
      final key = e.scheduledAt > 0 ? e.scheduledAt : e.ts;
      byScheduledAt.putIfAbsent(key, () => []);
      byScheduledAt[key]!.add(e);
    }

    final rows = <_LogRow>[];

    for (final entry in byScheduledAt.entries) {
      final scheduledAt = entry.key;
      final list = entry.value;

      // Find best "medicine name" from any event in this group
      // Usually title is: "Time for <medName>"
      final medName = _extractMedicineName(
        list.firstWhere((x) => x.title.trim().isNotEmpty, orElse: () => list.first).title,
      );

      // Decide final status:
      final taken = list.any((e) => e.action == 'TAKEN');
      if (taken) {
        rows.add(
          _LogRow(
            scheduledAt: scheduledAt,
            medicineName: medName,
            status: 'Taken',
            reason: null,
          ),
        );
        continue;
      }

      // If skipped now exists, show it with reason
      final skip = list.where((e) => e.action == 'SKIP_NOW').toList();
      if (skip.isNotEmpty) {
        // pick the latest SKIP_NOW in that group
        skip.sort((a, b) => b.ts.compareTo(a.ts));
        final reason = skip.first.reason;

        rows.add(
          _LogRow(
            scheduledAt: scheduledAt,
            medicineName: medName,
            status: 'Skipped',
            reason: (reason == null || reason.trim().isEmpty) ? null : reason.trim(),
          ),
        );
        continue;
      }

      // Otherwise: ignore (don’t show RING_SHOWN / SNOOZE / AUTO_TIMEOUT)
    }

    // newest first by scheduledAt
    rows.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return rows;
  }

  String _extractMedicineName(String title) {
    final t = title.trim();
    // common pattern in your code: "Time for <med.name>"
    const prefix = 'Time for ';
    if (t.startsWith(prefix) && t.length > prefix.length) {
      return t.substring(prefix.length).trim();
    }
    // fallback: use title directly
    return t.isEmpty ? 'Medicine' : t;
  }

  String _fmtDateTime(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');

    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    return "$y-$m-$d  $hh:$mm";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarm Logs')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
        onRefresh: _load,
        child: _rows.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 200),
            Center(child: Text('No taken/skip logs yet.')),
          ],
        )
            : ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: _rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = _rows[i];
            final isTaken = r.status == 'Taken';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isTaken
                        ? Colors.green.withOpacity(0.15)
                        : Colors.pinkAccent.withOpacity(0.15),
                    child: Icon(
                      isTaken ? Icons.check_circle : Icons.block,
                      color: isTaken ? Colors.green : Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date/time
                        Text(
                          _fmtDateTime(r.scheduledAt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Medicine name
                        Text(
                          r.medicineName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Status (and reason if skipped)
                        if (isTaken)
                          const Text(
                            'Taken',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        else
                          Text(
                            r.reason == null
                                ? 'Skipped'
                                : 'Skipped • ${r.reason}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LogRow {
  final int scheduledAt;
  final String medicineName;
  final String status; // Taken | Skipped
  final String? reason;

  _LogRow({
    required this.scheduledAt,
    required this.medicineName,
    required this.status,
    required this.reason,
  });
}