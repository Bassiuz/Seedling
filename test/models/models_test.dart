import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/models/task.dart';

void main() {
  group('Task', () {
    const full = Task(
      id: 't1',
      title: 'Afwas doen',
      tagId: 'home',
      date: '2026-07-21',
      time: '18:30',
      createdDate: '2026-07-20',
      completedOnDate: '2026-07-22',
    );

    const bare = Task(
      id: 't2',
      title: 'Bike when dry',
      date: '2026-07-21',
      createdDate: '2026-07-21',
    );

    test('survives a map roundtrip with every field set', () {
      final back = Task.fromMap(full.id, full.toMap());
      expect(back.toMap(), full.toMap());
      expect(back.id, full.id);
    });

    test('survives a map roundtrip with the optional fields null', () {
      final back = Task.fromMap(bare.id, bare.toMap());
      expect(back.toMap(), bare.toMap());
      expect(back.tagId, isNull);
      expect(back.time, isNull);
      expect(back.completedOnDate, isNull);
    });

    test('fromMap tolerates a document missing optional keys', () {
      final back = Task.fromMap('t3', {
        'title': 'Vet appointment',
        'date': '2026-07-15',
        'createdDate': '2026-07-15',
      });
      expect(back.title, 'Vet appointment');
      expect(back.tagId, isNull);
      expect(back.time, isNull);
      expect(back.completedOnDate, isNull);
    });

    test('isCompleted and isTimed read the optional fields', () {
      expect(full.isCompleted, isTrue);
      expect(full.isTimed, isTrue);
      expect(bare.isCompleted, isFalse);
      expect(bare.isTimed, isFalse);
    });

    test('copyWith sets completedOnDate', () {
      expect(bare.copyWith(completedOnDate: '2026-07-23').completedOnDate,
          '2026-07-23');
    });

    test('copyWith clears completedOnDate when asked', () {
      expect(full.copyWith(clearCompleted: true).completedOnDate, isNull);
      expect(full.copyWith(clearCompleted: true).isCompleted, isFalse);
    });

    test('copyWith preserves completedOnDate when the field is omitted', () {
      expect(full.copyWith(title: 'Renamed').completedOnDate, '2026-07-22');
    });

    test('copyWith moves the planned date but keeps createdDate (snooze)', () {
      final snoozed = full.copyWith(date: '2026-07-30');
      expect(snoozed.date, '2026-07-30');
      expect(snoozed.createdDate, full.createdDate);
    });
  });

  group('Tag', () {
    const tag = Tag(
      id: 'moxify',
      name: 'Moxify',
      colorIndex: 3,
      iconIndex: 2,
      sortOrder: 1,
    );

    test('survives a map roundtrip', () {
      final back = Tag.fromMap(tag.id, tag.toMap());
      expect(back.toMap(), tag.toMap());
      expect(back.id, 'moxify');
    });

    test('fromMap falls back to the first colour and icon when keys are absent',
        () {
      final back = Tag.fromMap('x', {'name': 'Untitled'});
      expect(back.colorIndex, 0);
      expect(back.iconIndex, 0);
      expect(back.sortOrder, 0);
    });
  });
}
