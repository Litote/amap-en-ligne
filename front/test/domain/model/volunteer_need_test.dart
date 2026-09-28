import 'package:amap_en_ligne/domain/model/volunteer_need.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 30, 10);

  VolunteerNeedLevel level(int current, int required, DateTime start) =>
      volunteerNeedLevel(
        current: current,
        required: required,
        start: start,
        now: now,
      );

  test('no badge without need or when at least 80 % staffed', () {
    final soon = now.add(const Duration(days: 1));
    expect(level(0, 0, soon), VolunteerNeedLevel.none);
    expect(level(4, 5, soon), VolunteerNeedLevel.none);
  });

  test('limited between 50 % and 80 %, whatever the date', () {
    expect(
      level(1, 2, now.add(const Duration(days: 1))),
      VolunteerNeedLevel.limited,
    );
    expect(
      level(1, 2, now.add(const Duration(days: 20))),
      VolunteerNeedLevel.limited,
    );
  });

  test('under 50 % is urgent only within three days', () {
    expect(
      level(0, 2, now.add(const Duration(days: 1))),
      VolunteerNeedLevel.urgent,
    );
    expect(
      level(0, 2, now.add(const Duration(days: 3))),
      VolunteerNeedLevel.urgent,
    );
    expect(
      level(0, 2, now.add(const Duration(days: 3, minutes: 1))),
      VolunteerNeedLevel.wanted,
    );
    expect(
      level(0, 2, now.add(const Duration(days: 15))),
      VolunteerNeedLevel.wanted,
    );
  });
}
