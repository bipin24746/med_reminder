import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class TimezoneService {
  static Future<void> init() async {
    tzdata.initializeTimeZones();
  }

  static tz.Location locationFromName(String name) {
    return tz.getLocation(name);
  }
}
