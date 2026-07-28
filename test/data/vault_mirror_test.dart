import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/data/vault_exporter.dart';
import 'package:seedling/data/vault_mirror.dart';
import 'package:seedling/models/someday_item.dart';
import 'package:seedling/models/tag.dart';
import 'package:seedling/models/task.dart';

const _day = '2026-07-27';

Task _task(String title, {String? done, Map<String, int> entries = const {}}) =>
    Task(
      id: title,
      title: title,
      date: _day,
      createdDate: _day,
      completedOnDate: done,
      timeEntries: entries,
    );

void main() {
  late Directory root;
  late VaultMirror mirror;

  setUp(() {
    root = Directory.systemTemp.createTempSync('seedling_mirror_test');
    // Zero debounce so the timer fires on the next event-loop turn.
    mirror = VaultMirror(VaultExporter(root), debounce: Duration.zero);
  });

  tearDown(() {
    mirror.dispose();
    root.deleteSync(recursive: true);
  });

  String read(String path) => File('${root.path}/$path').readAsStringSync();
  bool exists(String path) => File('${root.path}/$path').existsSync();

  /// Lets the zero-duration timer and the write itself complete.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('a changed day is written out', () async {
    mirror.day(
        dayKey: _day, tasks: [_task('Afwas doen')], tags: const {}, note: 'Hi');
    await settle();

    expect(read('days/2026/2026-07-27.md'), contains('- [ ] Afwas doen'));
    expect(mirror.writes, 1);
  });

  test('typing repeatedly produces one write, not one per keystroke', () async {
    for (final note in ['P', 'Pa', 'Par', 'Parchment day']) {
      mirror.day(dayKey: _day, tasks: const [], tags: const {}, note: note);
    }
    await settle();

    expect(mirror.writes, 1);
    expect(read('days/2026/2026-07-27.md'), contains('Parchment day'));
  });

  test('a rebuild that changed nothing writes nothing', () async {
    mirror.day(dayKey: _day, tasks: const [], tags: const {}, note: 'Same');
    await settle();
    expect(mirror.writes, 1);

    mirror.day(dayKey: _day, tasks: const [], tags: const {}, note: 'Same');
    await settle();

    expect(mirror.writes, 1, reason: 'identical content is not rewritten');
  });

  test('checking a task off counts as a change', () async {
    mirror.day(
        dayKey: _day, tasks: [_task('Afwas doen')], tags: const {}, note: '');
    await settle();

    mirror.day(
        dayKey: _day,
        tasks: [_task('Afwas doen', done: _day)],
        tags: const {},
        note: '');
    await settle();

    expect(mirror.writes, 2);
    expect(read('days/2026/2026-07-27.md'), contains('- [x] Afwas doen'));
  });

  test('logging time counts as a change', () async {
    mirror.day(
        dayKey: _day, tasks: [_task('Fix video')], tags: const {}, note: '');
    await settle();

    mirror.day(
      dayKey: _day,
      tasks: [_task('Fix video', entries: const {_day: 45})],
      tags: const {},
      note: '',
    );
    await settle();

    expect(read('days/2026/2026-07-27.md'), contains('45m'));
  });

  test('the tag and someday files follow their own changes', () async {
    mirror.sidecars(
      tags: const [
        Tag(id: 'moxify', name: 'Moxify', colorIndex: 0, iconIndex: 0, sortOrder: 0),
      ],
      someday: const [
        SomedayItem(id: '1', title: 'YOLO 26', tagId: 'moxify', priority: 0),
      ],
    );
    await settle();

    expect(read('tags.md'), contains('- Moxify'));
    expect(read('someday/moxify.md'), contains('YOLO 26'));
  });

  test('unchanged sidecars are not rewritten', () async {
    const tags = [
      Tag(id: 'a', name: 'A', colorIndex: 0, iconIndex: 0, sortOrder: 0),
    ];
    mirror.sidecars(tags: tags, someday: const []);
    await settle();
    final before = mirror.writes;

    mirror.sidecars(tags: tags, someday: const []);
    await settle();

    expect(mirror.writes, before);
  });

  test('flush writes a pending change straight away', () async {
    final slow = VaultMirror(VaultExporter(root),
        debounce: const Duration(minutes: 5));
    addTearDown(slow.dispose);

    slow.day(
        dayKey: _day, tasks: const [], tags: const {}, note: 'Half a sentence');
    expect(exists('days/2026/2026-07-27.md'), isFalse,
        reason: 'still waiting on the debounce');

    await slow.flush();

    expect(read('days/2026/2026-07-27.md'), contains('Half a sentence'));
  });

  test('a write that fails does not throw at the caller', () async {
    // A file where the day folder should go, so creating it must fail.
    final blocked = Directory.systemTemp.createTempSync('seedling_blocked');
    File('${blocked.path}/days').writeAsStringSync('not a folder');
    final broken =
        VaultMirror(VaultExporter(blocked), debounce: Duration.zero);
    addTearDown(() {
      broken.dispose();
      blocked.deleteSync(recursive: true);
    });

    broken.day(dayKey: _day, tasks: const [], tags: const {}, note: 'x');
    await settle();

    expect(broken.writes, 0, reason: 'the failure was swallowed, not counted');
  });
}
