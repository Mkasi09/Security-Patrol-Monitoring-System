import 'package:flutter_test/flutter_test.dart';
import 'package:magzmotron/models/patrol_shift.dart';

void main() {
  test('PatrolShift serializes scheduled assignments', () {
    final startsAt = DateTime(2026, 5, 23, 8);
    final endsAt = DateTime(2026, 5, 23, 16);
    final createdAt = DateTime(2026, 5, 22, 12);

    final shift = PatrolShift(
      id: 'shift_1',
      guardId: 'guard_1',
      guardName: 'Jane Guard',
      locationId: 'loc_1',
      locationName: 'Main Gate',
      startsAt: startsAt,
      endsAt: endsAt,
      notes: 'Front gate and parking sweep',
      createdAt: createdAt,
    );

    final restored = PatrolShift.fromMap(shift.toMap());

    expect(restored.id, 'shift_1');
    expect(restored.guardName, 'Jane Guard');
    expect(restored.locationName, 'Main Gate');
    expect(restored.status, 'scheduled');
    expect(restored.startsAt, startsAt);
    expect(restored.endsAt, endsAt);
  });
}
