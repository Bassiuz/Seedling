# Seedling Phase 1 — Core Notebook Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (separate session) or superpowers:subagent-driven-development (this session) to implement this plan task-by-task.

**Goal:** A running Seedling app (macOS + iOS + Android) showing a swipeable day page with Timed / Tasks / Note blocks, tasks with tags, the rollover rule, snooze, and a Firestore backend — every widget golden-tested.

**Architecture:** Firestore (project `seedling-461b0`, offline persistence) is the only database; a thin `SeedlingRepo` wraps it and streams all tasks/tags, with day-page filtering done client-side by pure functions in `lib/logic/`. UI is plain Flutter + StreamBuilder — no state-management package. Notebook theme built from the 15-color e-ink-safe palette in the design doc (`docs/plans/2026-07-27-seedling-design.md`).

**Tech Stack:** Flutter 3.44.2 via fvm · firebase_core / firebase_auth / cloud_firestore · intl · dev: fake_cloud_firestore, golden tests Moxify-style (tolerance comparator + bundled fonts, see `/Users/bassiuz/Projects/Moxify/test`).

**Conventions (apply to every task):**
- TDD: failing test → run → minimal code → run → commit.
- Every widget/screen gets a golden test; goldens live next to the test in `goldens/`.
- Every new folder gets a `README.md` (one line per file). Update `decisions.md` when a task says so.
- Run tests with `fvm flutter test <path>`. Commit after every green task, message style `feat: …` / `test: …` / `chore: …`, ending with the Claude Co-Authored-By trailer.

---

### Task 0: Project scaffold

**Files:** whole Flutter project; `engineering.md`, `decisions.md`, `.gitignore`

1. `cd /Users/bassiuz/Seedling && fvm use 3.44.2 --force` (first use finishes SDK setup; takes a few minutes).
2. `fvm flutter create . --org dev.bassiuz --project-name seedling --platforms=ios,android,macos --empty`
3. Delete the generated counter test if present (`test/widget_test.dart`).
4. Add deps: `fvm flutter pub add firebase_core firebase_auth cloud_firestore intl` and `fvm flutter pub add --dev fake_cloud_firestore`.
5. Write `engineering.md`: Flutter 3.44.2 via fvm; run `fvm flutter test`, `fvm flutter run -d macos`; Firebase project `seedling-461b0`; layout of `lib/` (models, logic, data, theme, screens, widgets); golden-test workflow (`--update-goldens` to regenerate).
6. Write `decisions.md` first entries: Firestore-only (no local DB) per design doc; no state-management package (StreamBuilder + setState); fonts Source Serif 4 + Source Sans 3 copied from Moxify (revisit per design open question); email/password auth for v1 (Apple/Google sign-in later — zero platform config now).
7. `fvm flutter test` (no tests yet, expect "No tests ran" or pass) and `fvm flutter analyze` clean.
8. Commit: `chore: scaffold Seedling Flutter project`.

### Task 1: Golden test infrastructure

**Files:**
- Create: `test/flutter_test_config.dart`, `test/util/golden/tolerance_golden_comparator.dart`, `test/util/golden/load_fonts.dart`, `test/util/golden/golden_utils.dart`, `test/util/README.md`
- Copy fonts from `/Users/bassiuz/Projects/Moxify/test/assets/fonts/` → `test/assets/fonts/`: `MaterialIcons-Regular.otf`, `Roboto-Regular.ttf`, `SourceSans3-{Regular,Medium,SemiBold,Bold}.ttf`, `SourceSerif4-SemiBold.ttf`, `SourceSerif4-SemiBoldItalic.ttf`, `NotoColorEmoji-Regular.ttf`. Also copy `SourceSans3-*` and `SourceSerif4-*` to `assets/fonts/` and declare both families in `pubspec.yaml`.

`tolerance_golden_comparator.dart`: copy Moxify's verbatim (class `ToleranceGoldenComparator extends LocalFileComparator`, passes when `result.diffPercent <= diffTolerance`).

`load_fonts.dart`: like Moxify's but without google_fonts — load MaterialIcons, Roboto, SourceSans3 family, SourceSerif4 family, NotoColorEmoji from `test/assets/fonts/`.

`flutter_test_config.dart`: Moxify pattern — threshold `0.0`, `await loadFonts()`, install `ToleranceGoldenComparator`.

`golden_utils.dart` — the four canonical sizes from the design doc plus wrapper:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/theme/seedling_theme.dart';

/// Canonical Seedling screen contexts (design doc: Responsive layouts).
enum GoldenSize {
  phone(Size(390, 844), 3),        // iPhone
  eink(Size(632, 840), 2),         // BigMe B7 portrait
  macNarrow(Size(500, 950), 2),    // half-height Mac window
  mac(Size(1440, 900), 2);         // Mac full screen

  const GoldenSize(this.logical, this.ratio);
  final Size logical;
  final double ratio;
}

void configureSize(WidgetTester tester, GoldenSize s) {
  tester.view.physicalSize = s.logical * s.ratio;
  tester.view.devicePixelRatio = s.ratio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget wrapApp(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SeedlingTheme.light(),
      home: home,
    );

/// One golden per size: goldens/<base>_<size>.png
void goldenForSizes(String name, String base, List<GoldenSize> sizes,
    Widget Function() build) {
  for (final s in sizes) {
    testWidgets('$name (${s.name})', (tester) async {
      configureSize(tester, s);
      await tester.pumpWidget(wrapApp(build()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/${base}_${s.name}.png'));
    });
  }
}
```

Verify: write `test/theme/theme_gallery_test.dart` in Task 2 — infra compiles when that runs. For now `fvm flutter analyze` clean → commit `test: golden test infrastructure (Moxify-style)`.

### Task 2: Palette + theme + gallery golden

**Files:**
- Create: `lib/theme/seedling_palette.dart`, `lib/theme/seedling_theme.dart`, `lib/theme/README.md`
- Test: `test/theme/theme_gallery_test.dart`

`seedling_palette.dart` — the 15 e-ink tokens from the design doc (`ink #000000`, `grayDark #555555`, `gray #888888`, `grayLight #C4C4C4`, `red #FF0022`, `green #00CC44`, `blue #1122DD`, `cyan #00DDDD`, `orange #FF9900`, `yellow #FFEE00`, `greenDeep #2E8B57`, `purple #7B2FBE`, `azure #1E90FF`, `crimson #D81B60`, `magenta #FF00CC`) as `static const Color`, plus `paper = Color(0xFFF9F5EC)`, `paperLine = Color(0xFFE8E0CE)`, and `static const List<Color> tagColors` (the 11 non-gray accents).

`seedling_theme.dart` — `SeedlingTheme.light()`: `scaffoldBackgroundColor: paper`; textTheme: `SourceSerif4` for headline/title styles, `SourceSans3` for body/label; `colorScheme.primary: SeedlingPalette.greenDeep`; rounded shapes. Keep it one file, no theme extensions yet.

TDD: first write `theme_gallery_test.dart` — a private gallery widget (rows of all palette swatches with names, one line of each text style) rendered via `goldenForSizes('theme gallery', 'theme_gallery', [GoldenSize.phone], …)`. Run (fails: theme files missing) → implement → `fvm flutter test test/theme --update-goldens` → run again without flag → PASS → eyeball the PNG (serif headers? cream paper? colors right?) → commit `feat: seedling palette and notebook theme`.

### Task 3: Day keys (date helpers)

**Files:** Create: `lib/logic/day_key.dart`, `lib/logic/README.md` · Test: `test/logic/day_key_test.dart`

Day keys are `yyyy-MM-dd` strings (sort = chronology). Pure functions:

```dart
String dayKeyOf(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime dateOfKey(String key) => DateTime.parse(key);
String addDays(String key, int days) => dayKeyOf(dateOfKey(key).add(Duration(days: days)));
String todayKey() => dayKeyOf(DateTime.now());
```

Tests: formatting/padding, roundtrip, `addDays` across month/year/DST boundaries (e.g. `2026-03-29` +1 in Europe/Amsterdam). Red → green → commit `feat: day key helpers`.

### Task 4: Models — Task & Tag

**Files:** Create: `lib/models/task.dart`, `lib/models/tag.dart`, `lib/models/README.md` · Test: `test/models/models_test.dart`

Immutable classes with `toMap()`/`fromMap(id, map)` and `copyWith`. Task fields per design: `id, title, tagId?, date, time? (HH:mm), createdDate, completedOnDate?`; `bool get isCompleted => completedOnDate != null`; `bool get isTimed => time != null`. Tag: `id, name, colorIndex (into SeedlingPalette.tagColors), icon (IconData codePoint int), sortOrder`. TimeEntries are Phase 2 — omit.

Tests: roundtrip serialization incl. nulls; `copyWith` clearing `completedOnDate` (use a sentinel or explicit `clearCompleted` flag — test it). Commit `feat: task and tag models`.

### Task 5: Rollover logic (the core rule)

**Files:** Create: `lib/logic/rollover.dart` · Test: `test/logic/rollover_test.dart`

```dart
/// Design doc "Rollover": visible on D ⟺ date == D, or date < D ≤ (completedOnDate ?? today).
bool taskVisibleOn(Task t, String day, String today) {
  if (t.date == day) return true;
  if (day.compareTo(t.date) < 0) return false;
  final end = t.completedOnDate ?? today;
  return day.compareTo(end) <= 0;
}

enum TaskCheckState { open, checkedHere, doneLater }

TaskCheckState checkStateOn(Task t, String day) {
  if (t.completedOnDate == null) return TaskCheckState.open;
  return t.completedOnDate == day ? TaskCheckState.checkedHere : TaskCheckState.doneLater;
}

/// Tasks for day page D, timed first by time then untimed by createdDate.
List<Task> tasksForDay(List<Task> all, String day, String today) { … }
```

Tests must encode the user's example verbatim: planned Tue `2026-07-21`, today Thu `2026-07-23`, completed on Wed page → visible Tue (doneLater) + Wed (checkedHere), NOT Thu. Plus: open task carries to today but not tomorrow; future-planned only on its day; snoozed task (date moved) vanishes from today; completing today on today; sorting. Commit `feat: rollover visibility rules`.

### Task 6: SeedlingRepo (Firestore, fake-tested)

**Files:** Create: `lib/data/seedling_repo.dart`, `lib/data/README.md` · Test: `test/data/seedling_repo_test.dart`

Constructor takes `FirebaseFirestore` + `uid`. Paths per design doc data model (`users/{uid}/tasks|tags|days`).

```dart
Stream<List<Task>> watchTasks();          // whole collection, ordered client-side
Stream<List<Tag>> watchTags();
Stream<String> watchNote(String dayKey);  // days/{key}.note, '' default
Future<void> addTask(String title, {String? tagId, required String date, String? time});
Future<void> setCompleted(Task t, String? onDayKey);   // null = uncheck
Future<void> snooze(Task t, String toDayKey);          // updates date
Future<void> saveNote(String dayKey, String text);
Future<void> upsertTag(Tag t); Future<void> deleteTask(Task t);
```

`// ponytail: single all-tasks listener; add date-bounded queries if the collection gets big.`

Tests with `FakeFirebaseFirestore`: add→watch roundtrip, complete/uncheck, snooze changes date, note save/watch. Commit `feat: firestore repo`.

### Task 7: DayHeader widget

**Files:** Create: `lib/widgets/day_header.dart`, `lib/widgets/README.md` · Test: `test/widgets/day_header_test.dart`

Serif date ("Wednesday" big, "July 15, 2026" under it) from `dayKey` via `intl` (`DateFormat('EEEE')` / `DateFormat('MMMM d, y')`, locale en). Above it a Yesterday / **Today** / Tomorrow segmented control (callbacks: `onJump(int deltaFromToday)`), highlighting whichever of the three the shown day is (none when further away). Goldens: today selected (phone), an arbitrary past date (phone). Commit.

### Task 8: TaskTile widget

**Files:** Create: `lib/widgets/task_tile.dart`, `lib/widgets/tag_chip.dart` · Test: `test/widgets/task_tile_test.dart`

Big round checkbox (~28pt circle, 2px ink border; filled with tag color + white check when done), title (strikethrough+gray when done), optional `TagChip` (small rounded chip, tag color, icon+name), optional time prefix for timed tasks, carried annotation ("from Jul 21", grayDark italic small) when `task.date != shownDay`, doneLater state: grayed circle with small check + "done Wed 22" annotation, non-interactive. Long-press → menu (Snooze… / Delete) via callback. Goldens (phone): open / open-with-tag-carried / checkedHere / doneLater / timed. Commit.

### Task 9: Blocks — Timed, Tasks, Note

**Files:** Create: `lib/widgets/timed_block.dart`, `lib/widgets/tasks_block.dart`, `lib/widgets/note_block.dart`, `lib/widgets/add_task_field.dart`, `lib/widgets/block_frame.dart` · Test: `test/widgets/blocks_test.dart`

`BlockFrame`: shared section chrome — serif small-caps-ish title with tiny icon, hairline divider, padding; paper stays flat (no cards).

- `TimedBlock(tasks, shownDay, onToggle, onMenu)` — time-sorted `TaskTile`s; empty → single grayLight line "Nothing timed".
- `TasksBlock(tasks, tags, shownDay, onToggle, onMenu, onAdd)` — untimed tiles + `AddTaskField` at bottom (round ghost checkbox + hint "Add a task…", submit → `onAdd(title)`; tag defaults to none; time/tag picking arrives in Task 12).
- `NoteBlock(initialText, onChanged)` — borderless multiline `TextField` on ruled lines (a `CustomPainter` drawing `paperLine` horizontals at line-height intervals), monospace-free body font. Markdown stored as-is, no preview in Phase 1 (decisions.md entry).

Goldens (phone + eink): each block empty and filled. Commit.

### Task 10: DayPage — responsive assembly + paging

**Files:** Create: `lib/screens/day_page.dart`, `lib/screens/README.md` · Test: `test/screens/day_page_test.dart`

`DayView(repo-fed data in, callbacks out)` — pure presentational widget the goldens render; `DayPage(repo)` — stateful: `PageView.builder` (index anchor 500000 = today; page↔dayKey via `addDays`), StreamBuilders on `watchTasks`/`watchTags`, note editing with 500ms debounce save, `// ponytail: last-writer-wins note saves`. Toggle logic: open→`setCompleted(t, shownDay)`, checkedHere→`setCompleted(t, null)`, doneLater→no-op. Snooze menu → `showDatePicker` → `repo.snooze`.

Layout via `LayoutBuilder` per design table: `<600` stacked scroll; `600–1000` two columns (Timed+Tasks | Note); `>1000` three columns. 

Goldens of `DayView` with fixture data (3 timed, 4 tasks incl. carried+done states, a note) at **all four** `GoldenSize`s, plus one empty-day phone golden. Widget test: tapping a checkbox fires callback. Commit `feat: day page`.

### Task 11: Firebase wiring + auth gate

**Files:** Create: `lib/main.dart`, `lib/app.dart`, `lib/screens/sign_in_screen.dart` · Modify: platform configs via flutterfire · Test: `test/screens/sign_in_screen_test.dart`

1. `dart pub global activate flutterfire_cli` (if needed), then `flutterfire configure --project=seedling-461b0 --platforms=ios,android,macos --yes`. **May require `firebase login` — if the CLI isn't authed, STOP and ask the user to run it.** Generates `lib/firebase_options.dart`.
2. macOS needs network entitlements: add `com.apple.security.network.client` to both `macos/Runner/*.entitlements`.
3. `main.dart`: init Firebase, enable Firestore persistence (default on mobile; `Settings(persistenceEnabled: true)` for macOS), run `SeedlingApp`.
4. `app.dart`: MaterialApp(theme) → StreamBuilder on `authStateChanges()` → `SignInScreen` or `DayPage(SeedlingRepo(firestore, uid))`.
5. `SignInScreen`: email + password fields on paper, one "Sign in" button — try `signInWithEmailAndPassword`, on `user-not-found` create the account. Extract the form as `SignInForm(onSubmit)` so the golden needs no Firebase. Enable Email/Password provider in the Firebase console (ask user if it fails).
6. Golden: `SignInForm` phone + mac. Commit `feat: firebase auth gate`.

### Task 12: Add-task affordances — tag & time pick, tags screen

**Files:** Create: `lib/screens/tags_screen.dart`, modify `add_task_field.dart`, `day_page.dart` · Test: `test/screens/tags_screen_test.dart`, extend `test/widgets/blocks_test.dart`

- `AddTaskField` gains two trailing ghost icons: tag (opens bottom sheet listing tags → picked tag chips onto the field) and clock (`showTimePicker` → task becomes timed).
- `TagsScreen` (from a leaf icon in the day header): list tags, add/edit sheet — name field, color picker as a wrap of `SeedlingPalette.tagColors` swatch circles, icon picker from a fixed const list of ~12 Material icons. Saves via `repo.upsertTag`.
- Goldens: tags screen with fixtures (phone, eink), add-sheet, AddTaskField with tag selected. Commit.

### Task 13: Smoke run + docs sweep

1. `fvm flutter test` — full suite green.
2. `fvm flutter analyze` — clean.
3. `fvm flutter run -d macos` — sign in with a test account, add a task, check it off, write a note, restart app, confirm persistence + sync in Firebase console. (Screenshot for the user.)
4. Verify every `lib/` and `test/` folder has its README.md; `engineering.md` current; `decisions.md` has entries from Tasks 0, 9, 11.
5. Commit `chore: phase 1 complete`.

---

**Out of scope (later phases, per design doc):** daily questions, someday lists, time entries, calendar/EventKit + blacklist, week reviews, vault export, e-ink display mode, widgets, markdown preview.
