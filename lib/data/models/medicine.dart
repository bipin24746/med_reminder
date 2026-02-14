class Medicine {
  final int? id;
  final String name;
  final String? note;
  final int timesPerDay;
  final int days;
  final String timezone;
  final String timesJson;
  final int startDateMillis;

  // ✅ NEW
  final String form;        // e.g. "pill", "liquid"
  final String doseAmount;  // e.g. "1 tablet", "5 ml"

  Medicine({
    this.id,
    required this.name,
    this.note,
    required this.timesPerDay,
    required this.days,
    required this.timezone,
    required this.timesJson,
    required this.startDateMillis,
    required this.form,
    required this.doseAmount,
  });

  Medicine copyWith({int? id}) => Medicine(
    id: id ?? this.id,
    name: name,
    note: note,
    timesPerDay: timesPerDay,
    days: days,
    timezone: timezone,
    timesJson: timesJson,
    startDateMillis: startDateMillis,
    form: form,
    doseAmount: doseAmount,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'note': note,
    'timesPerDay': timesPerDay,
    'days': days,
    'timezone': timezone,
    'timesJson': timesJson,
    'startDateMillis': startDateMillis,
    // ✅ NEW
    'form': form,
    'doseAmount': doseAmount,
  };

  static Medicine fromMap(Map<String, Object?> map) => Medicine(
    id: map['id'] as int?,
    name: map['name'] as String,
    note: map['note'] as String?,
    timesPerDay: map['timesPerDay'] as int,
    days: map['days'] as int,
    timezone: map['timezone'] as String,
    timesJson: map['timesJson'] as String,
    startDateMillis: map['startDateMillis'] as int,
    // ✅ NEW
    form: (map['form'] as String?) ?? 'pill',
    doseAmount: (map['doseAmount'] as String?) ?? '1',
  );
}
