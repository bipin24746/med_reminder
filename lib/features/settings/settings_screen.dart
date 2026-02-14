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
  static const String _kMode = 'alarm_sound_mode'; // system | picked
  static const String _kPickedUri = 'alarm_picked_uri';
  static const String _kAlsoApp = 'alarm_also_app_sound';

  bool _loading = true;

  // ✅ dropdown minutes
  final List<int> _minuteOptions = const [5, 10, 15, 20, 25, 30];

  int _selectedMinutes = 5; // ✅ default UI selection = 5
  int _savedMinutes = 5;    // for display only

  String _soundMode = 'system';
  String? _pickedUri;
  bool _alsoPlayAppSound = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();

    final savedSec = sp.getInt(_kDuration) ?? 300; // ✅ default 5 min
    final savedMin = (savedSec / 60).round();

    _savedMinutes = _minuteOptions.contains(savedMin) ? savedMin : 5;
    _selectedMinutes = _savedMinutes;

    _soundMode = sp.getString(_kMode) ?? 'system';
    _pickedUri = sp.getString(_kPickedUri);
    _alsoPlayAppSound = sp.getBool(_kAlsoApp) ?? true;

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();

    await sp.setInt(_kDuration, _selectedMinutes * 60); // ✅ save seconds
    await sp.setString(_kMode, _soundMode);
    await sp.setBool(_kAlsoApp, _alsoPlayAppSound);
    if (_pickedUri != null) {
      await sp.setString(_kPickedUri, _pickedUri!);
    }

    setState(() => _savedMinutes = _selectedMinutes);

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

      // ✅ NOT saving automatically — user must press Save
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
            'Alarm duration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<int>(
            value: _selectedMinutes,
            decoration: const InputDecoration(labelText: 'Duration (minutes)'),
            items: _minuteOptions
                .map((m) => DropdownMenuItem(
              value: m,
              child: Text('$m minutes'),
            ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selectedMinutes = v);
            },
          ),

          const SizedBox(height: 8),
          Text('Current saved: $_savedMinutes minutes'),

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
                _pickedUri = null; // ✅ clear picked tone
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
            onTap: _pickAlarmTone, // keep enabled OR disable if you want
          ),


          // SwitchListTile(
          //   title: const Text('Also play app alarm sound (alarm.mp3)'),
          //   subtitle: const Text('Plays together with selected tone'),
          //   value: _alsoPlayAppSound,
          //   onChanged: (v) => setState(() => _alsoPlayAppSound = v),
          // ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _save, // ✅ Save-only
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
