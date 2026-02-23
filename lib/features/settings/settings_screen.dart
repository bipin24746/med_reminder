import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const MethodChannel _channel = MethodChannel('alarm_settings');

  static const String _kDuration = 'alarm_duration_sec';
  static const String _kSnoozeSec = 'alarm_snooze_sec'; // ✅ NEW
  static const String _kMode = 'alarm_sound_mode'; // system | picked | app
  static const String _kPickedUri = 'alarm_picked_uri';

  bool _loading = true;

  final List<int> _minuteOptions = const [5, 10, 15, 20, 25, 30];

  int _selectedDurationMin = 5;
  int _savedDurationMin = 5;

  int _selectedSnoozeMin = 5; // ✅ NEW
  int _savedSnoozeMin = 5;    // ✅ NEW

  String _soundMode = 'system';
  String? _pickedUri;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();

    final savedDurationSec = sp.getInt(_kDuration) ?? 300;
    final savedDurationMin = (savedDurationSec / 60).round();
    _savedDurationMin = _minuteOptions.contains(savedDurationMin) ? savedDurationMin : 5;
    _selectedDurationMin = _savedDurationMin;

    // ✅ Snooze
    final savedSnoozeSec = sp.getInt(_kSnoozeSec) ?? 300;
    final savedSnoozeMin = (savedSnoozeSec / 60).round();
    _savedSnoozeMin = _minuteOptions.contains(savedSnoozeMin) ? savedSnoozeMin : 5;
    _selectedSnoozeMin = _savedSnoozeMin;

    _soundMode = sp.getString(_kMode) ?? 'system';
    _pickedUri = sp.getString(_kPickedUri);

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();

    await sp.setInt(_kDuration, _selectedDurationMin * 60);
    await sp.setInt(_kSnoozeSec, _selectedSnoozeMin * 60); // ✅ NEW
    await sp.setString(_kMode, _soundMode);

    if (_pickedUri != null) {
      await sp.setString(_kPickedUri, _pickedUri!);
    }

    setState(() {
      _savedDurationMin = _selectedDurationMin;
      _savedSnoozeMin = _selectedSnoozeMin;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  Future<void> _pickAlarmTone() async {
    try {
      final uri = await _channel.invokeMethod<String>('pickAlarmTone');
      if (!mounted) return;

      if (uri == null || uri.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tone selected')),
        );
        return;
      }

      setState(() {
        _pickedUri = uri;
        _soundMode = 'picked';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pick failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Alarm duration (ring time)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<int>(
            value: _selectedDurationMin,
            decoration: const InputDecoration(labelText: 'Duration (minutes)'),
            items: _minuteOptions
                .map((m) => DropdownMenuItem(value: m, child: Text('$m minutes')))
                .toList(),
            onChanged: (v) => setState(() => _selectedDurationMin = v ?? 5),
          ),
          const SizedBox(height: 8),
          Text('Saved duration: $_savedDurationMin minutes'),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          const Text(
            'Snooze time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<int>(
            value: _selectedSnoozeMin,
            decoration: const InputDecoration(labelText: 'Snooze (minutes)'),
            items: _minuteOptions
                .map((m) => DropdownMenuItem(value: m, child: Text('$m minutes')))
                .toList(),
            onChanged: (v) => setState(() => _selectedSnoozeMin = v ?? 5),
          ),
          const SizedBox(height: 8),
          Text('Saved snooze: $_savedSnoozeMin minutes'),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          const Text(
            'Alarm tone',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          RadioListTile<String>(
            value: 'system',
            groupValue: _soundMode,
            onChanged: (v) {
              setState(() {
                _soundMode = 'system';
                _pickedUri = null;
              });
            },
            title: const Text('Use system default alarm tone'),
          ),

          ListTile(
            title: const Text('Pick alarm tone from device'),
            subtitle: Text(
              _soundMode == 'system'
                  ? 'Using system default'
                  : (_pickedUri ?? 'No tone picked'),
            ),
            trailing: const Icon(Icons.music_note),
            onTap: _pickAlarmTone,
          ),

          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}