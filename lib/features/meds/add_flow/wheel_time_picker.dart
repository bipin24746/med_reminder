import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<TimeOfDay?> showWheelTimePicker(
    BuildContext context, {
      required TimeOfDay initial,
    }) async {
  // convert initial to 12h + am/pm
  int selMinute = initial.minute;
  int selAmPm = initial.hour >= 12 ? 1 : 0; // 0=AM, 1=PM
  int selHour12 = _toHour12(initial.hour); // 1..12

  // "infinite" looping simulation sizes
  const int hourLoopCount = 2400; // plenty
  const int minuteLoopCount = 6000;

  // middle aligned so user can scroll up/down a lot
  final int hourBase = hourLoopCount ~/ 2 - ((hourLoopCount ~/ 2) % 12);
  final int minuteBase = minuteLoopCount ~/ 2 - ((minuteLoopCount ~/ 2) % 60);

  // initial wheel indices
  final int initHourIndex = hourBase + (selHour12 - 1); // 0..11 maps to 1..12
  final int initMinuteIndex = minuteBase + selMinute;

  final hourCtrl = FixedExtentScrollController(initialItem: initHourIndex);
  final minuteCtrl = FixedExtentScrollController(initialItem: initMinuteIndex);
  final ampmCtrl = FixedExtentScrollController(initialItem: selAmPm);

  final result = await showModalBottomSheet<TimeOfDay>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (ctx) {
      // keep it sized so it never collapses
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: StatefulBuilder(
            builder: (ctx, setState) {
              String preview() {
                final h24 = _toHour24(selHour12, selAmPm);
                return _format(TimeOfDay(hour: h24, minute: selMinute));
              }

              return SizedBox(
                height: 340,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, null),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          Text(
                            preview(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              final h24 = _toHour24(selHour12, selAmPm);
                              Navigator.pop(ctx, TimeOfDay(hour: h24, minute: selMinute));
                            },
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    Expanded(
                      child: Row(
                        children: [
                          // HOURS 1..12 infinite
                          Expanded(
                            child: CupertinoPicker.builder(
                              scrollController: hourCtrl,
                              itemExtent: 44,
                              useMagnifier: true,
                              magnification: 1.12,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  selHour12 = (index % 12) + 1; // 1..12
                                });
                              },
                              childCount: hourLoopCount,
                              itemBuilder: (_, index) {
                                final v = (index % 12) + 1;
                                return Center(
                                  child: Text(
                                    v.toString(),
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                                  ),
                                );
                              },
                            ),
                          ),

                          // MINUTES 00..59 infinite
                          Expanded(
                            child: CupertinoPicker.builder(
                              scrollController: minuteCtrl,
                              itemExtent: 44,
                              useMagnifier: true,
                              magnification: 1.12,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  selMinute = index % 60;
                                });
                              },
                              childCount: minuteLoopCount,
                              itemBuilder: (_, index) {
                                final v = index % 60;
                                return Center(
                                  child: Text(
                                    v.toString().padLeft(2, '0'),
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                                  ),
                                );
                              },
                            ),
                          ),

                          // AM/PM NOT infinite (only two)
                          SizedBox(
                            width: 90,
                            child: CupertinoPicker(
                              scrollController: ampmCtrl,
                              itemExtent: 44,
                              useMagnifier: true,
                              magnification: 1.12,
                              onSelectedItemChanged: (i) {
                                setState(() => selAmPm = i.clamp(0, 1));
                              },
                              children: const [
                                Center(
                                  child: Text('AM',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                                ),
                                Center(
                                  child: Text('PM',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );

  // dispose controllers (important)
  hourCtrl.dispose();
  minuteCtrl.dispose();
  ampmCtrl.dispose();

  return result;
}

// --- helpers ---

int _toHour12(int hour24) {
  final h = hour24 % 12;
  return h == 0 ? 12 : h;
}

int _toHour24(int hour12, int ampm) {
  // ampm: 0=AM, 1=PM
  if (ampm == 0) return hour12 == 12 ? 0 : hour12;
  return hour12 == 12 ? 12 : hour12 + 12;
}

String _format(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$h:$m $ampm';
}