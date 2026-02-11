class AlarmId {
  static const int slotSize = 10000; // supports up to 9999 alarms per medicine

  static int make(int medicineId, int idx) => medicineId * slotSize + idx;

  // how many ids we might have used per medicine (safe upper bound)
  static const int maxSlots = slotSize;
}
