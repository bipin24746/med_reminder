import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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

  int _durationSec = 10;
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
    setState(() {
      _durationSec = sp.getInt(_kDuration) ?? 10;
      _soundMode = sp.getString(_kMode) ?? 'system';
      _pickedUri = sp.getString(_kPickedUri);
      _alsoPlayAppSound = sp.getBool(_kAlsoApp) ?? true;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kDuration, _durationSec);
    await sp.setString(_kMode, _soundMode);
    await sp.setBool(_kAlsoApp, _alsoPlayAppSound);
    if (_pickedUri != null) {
      await sp.setString(_kPickedUri, _pickedUri!);
    }

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

      await _save();
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
          Slider(
            value: _durationSec.toDouble().clamp(5, 120),
            min: 5,
            max: 120,
            divisions: 23,
            label: '$_durationSec sec',
            onChanged: (v) => setState(() => _durationSec = v.round()),
            onChangeEnd: (_) => _save(),
          ),
          Text('Rings for $_durationSec seconds'),

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
            onChanged: (v) async {
              setState(() => _soundMode = 'system');
              await _save();
            },
            title: const Text('Use system default alarm tone'),
          ),

          ListTile(
            title: const Text('Pick alarm tone from device'),
            subtitle: Text(_pickedUri ?? 'No tone picked'),
            trailing: const Icon(Icons.music_note),
            onTap: _pickAlarmTone,
          ),

          ListTile(
            title: const Text("Enable Alarm Permissions"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/permissions'),
          ),


          // SwitchListTile(
          //   title: const Text('Also play app alarm sound (alarm.mp3)'),
          //   subtitle: const Text('Plays together with selected tone'),
          //   value: _alsoPlayAppSound,
          //   onChanged: (v) async {
          //     setState(() => _alsoPlayAppSound = v);
          //     await _save();
          //   },
          // ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
