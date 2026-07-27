# Seedling — Design

*2026-07-27 — expanded from the Parchment-inspired wish list. Not an implementation plan; this is what we're building and why.*

Seedling is a personal daily-planning notebook: one page per day showing timed calendar items, a checkable task list, quick daily questions, and a free-form note — wrapped in a warm paper/serif notebook aesthetic. Flutter, running on iPhone, macOS, and a BigMe B7 e-ink tablet. Data syncs through Firestore; the Mac app mirrors everything to Markdown files so AI agents can query the archive.

## Locked decisions

| Decision | Choice |
|---|---|
| Name | Seedling |
| Data & sync | Firestore (offline persistence on) is the database — no separate local DB, no custom sync engine |
| .md export | The macOS app writes a one-way Markdown mirror ("the vault") on data changes |
| Calendar | Apple Calendar via EventKit (`device_calendar`) on iPhone/Mac; BigMe renders a synced event mirror |
| BigMe B7 | v1 target: check-off, daily questions, typed notes, e-ink theme. No stylus ink in v1 |
| Stack standards | TDD, golden test for every widget and screen (Moxify-style tolerance comparator), `decisions.md`, `engineering.md`, README.md in every folder |

## The day page

The core model is **one page per day** with four blocks:

1. **Timed** — calendar events (time-sorted) and tasks that have a time. Blacklisted events hidden.
2. **Tasks** (no time) — checkable list with tag chips, big round checkboxes.
3. **Daily questions** — configurable quick check-offs (see below). Collapses to one line ("All answered · 2/2") once complete.
4. **Daily note** — markdown text on lined paper.

Navigation: horizontal swipe pages between days (`PageView`), plus a Yesterday / **Today** / Tomorrow control and a calendar date picker. Today is always one tap away.

### Responsive layouts

| Context | Layout |
|---|---|
| iPhone / narrow Mac window (<600pt wide) | Blocks stacked vertically, scrolling page |
| Mid width (600–1000pt) | Two columns: Timed + Tasks + Questions left, Note right |
| Mac full screen (>1000pt) | Three columns: Timed · Tasks/Questions · Note |
| BigMe B7 (7" portrait) | Stacked like phone, larger touch targets, paged not scrolled |

Every layout is golden-tested at a canonical size for each context.

## Tasks

A task has: title, optional tag, planned date, optional time, optional snooze-moved date, completion state, and time entries.

**Tags/projects** — name + color + icon, user-defined, shown as a small chip on each task. Filterable. Tag colors are picked from the e-ink-safe palette (below), so a tag looks the same on the iPhone, the Mac, and the BigMe.

**Rollover** — the rule, derived from the wish list:

- A task appears on its planned date's page.
- If uncompleted, it also appears on **Today** (carried over, visually marked "from Jul 26"). Carryover renders only on Today — past pages show exactly what was planned there plus what was completed there, so history stays honest.
- Completing a task **anywhere** (including going back to yesterday's page) completes it once, recording *which day page* it was checked on. It immediately stops appearing as carryover everywhere else.
- Future pages show only tasks planned/snoozed to that day.

**Snooze** — pick a date; the task's planned date moves there (original creation date kept for history). Gone from today, appears there.

**Time entries** — a stepper on each task logs work in 15-minute increments, stored per day (`{date, minutes}`). Shown as a small total on the task; fully written out in the .md export for later administration.

**Someday lists** — one priority-ordered list per tag. Two flows:
- *Dump*: add an idea straight to a tag's someday list from anywhere.
- *Pull*: when adding a task to today, a "from someday" affordance shows the **top 3–5 items by priority** (for the selected tag, or across tags) — tap one to promote it to today and remove it from someday.

## Daily questions

Configurable in settings: each question has a label, optional emoji, and a type — either **choice chips** (e.g. *Work travel: Home / OV / Bike*) or a plain **check**. Answers are stored per day. The block collapses with a summary line when everything is answered. Questions can be deactivated without losing historical answers.

## Week review

A dedicated review page per week, prompted from **Sunday** and badged until completed; reachable from Monday's day page thereafter.

The **review template** is configured once and generates each week's review:

- **Goal blocks** — *Yearly goals* and *Quarterly goals*, edited rarely in the template. When a review is generated, the current goals are **snapshotted into it**, so old reviews forever show the goals as they were then.
- **Question blocks** — repeating prompts ("What did I do since last week review?", "What will be a lasting memory?", "What do I leave behind?").
- **Mood log block** — free bullets where each line starts from an emoji palette you define (🤔 ⏲️ 😢 😄 🦴 🎰 💻 …), for quick mood-bundled observations.

Reviews export to `reviews/2026-W31.md` in the vault.

## Calendar & blacklist

- iPhone/Mac read Apple Calendar read-only via EventKit. No event editing in v1 — Seedling is a lens, not a calendar client.
- Apple devices write the next ~60 days of events into a Firestore `calendarMirror` collection so the **BigMe** can render the Timed block without iCloud access.
- **Blacklist**: hide an event (by recurring-event identity, falling back to exact title) via its context menu. Hidden events vanish from the Timed block.
- **Reveal**: on Mac, a keyboard shortcut (⌘⇧H) toggles reveal mode — hidden events show grayed with an "unhide" action. On all platforms, Settings → Hidden events lists the rules as a fallback.

## Data model (Firestore)

```
users/{uid}/
  tags/{tagId}            name, color, icon, sortOrder
  tasks/{taskId}          title, tagId?, date, time?, createdDate,
                          completedAt?, completedOnDate?, timeEntries[]
  days/{yyyy-MM-dd}       note (markdown), questionAnswers{}
  someday/{itemId}        tagId, title, priority
  reviews/{weekStart}     snapshot of goal blocks + answers
  config/questions        ordered question definitions
  config/reviewTemplate   goal blocks + question blocks + emoji palette
  config/blacklist        hide rules
  calendarMirror/{id}     written by Apple devices, read by BigMe
```

Firebase Auth (Sign in with Apple or Google) ties all devices to one uid; security rules restrict data to that uid. Firestore offline persistence gives local-first behavior for free.

## Markdown vault (export)

The macOS app owns a folder, e.g. `~/Seedling Vault/`:

```
days/2026/2026-07-27.md     agenda · tasks with [x]/[ ], tag, time logged · question answers · note verbatim
reviews/2026-W31.md
someday/<tag>.md
tags.md
```

One-way, debounced mirror: files are regenerated when their source data changes and are never read back. Safe for any AI agent or Obsidian to read.

## E-ink mode & the Seedling palette

A display mode (auto-suggested on the BigMe, manually toggleable): black-on-white base, zero animations, instant page transitions, thicker strokes, oversized checkboxes, pagination over scrolling. Same app, same data.

The BigMe B7 is a **color** e-ink panel with a fixed set of displayable colors. That set is the app-wide accent palette — colors are authored fully saturated (the panel desaturates them itself), so everything designed on LCD renders correctly on e-ink with no per-mode color mapping:

| Token | Hex | | Token | Hex |
|---|---|---|---|---|
| ink | `#000000` | | orange | `#FF9900` |
| gray-dark | `#555555` | | yellow | `#FFEE00` |
| gray | `#888888` | | green-deep | `#2E8B57` |
| gray-light | `#C4C4C4` | | purple | `#7B2FBE` |
| red | `#FF0022` | | azure | `#1E90FF` |
| green | `#00CC44` | | crimson | `#D81B60` |
| blue | `#1122DD` | | magenta | `#FF00CC` |
| cyan | `#00DDDD` | | | |

Tag colors, mood emphasis, and chart-like accents all come from these tokens. High-contrast e-ink mode keeps the accents but drops textures, shadows, and mid-gray text (body text is pure ink).

## iPhone widget

One medium home-screen widget via `home_widget` + a small WidgetKit extension: next timed item plus the top unchecked tasks for today. More sizes later if the first one earns it.

## Styling

Notebook vibe throughout: subtle paper texture, ruled lines under the note area, a serif display font for the date header and section titles, a highly legible text font for user content, big round checkboxes with an ink-fill check (disabled in e-ink mode). Warm light theme first; dark and e-ink themes derive from the same tokens.

## Testing & repo standards

- TDD for all logic; rollover/snooze/carryover rules implemented as pure, unit-tested functions.
- A golden test for every widget and every screen state, at the four canonical sizes, using Moxify's approach (`flutter_test_config.dart` with font loading + tolerance comparator; goldens organized per widget folder — see `/Users/bassiuz/Projects/Moxify/test`).
- `decisions.md` — running log of choices and why. `engineering.md` — stack, commands, architecture. Every folder gets a README.md saying what's in it and what each file is for.

## Phasing

1. **Core notebook** — day page (all four blocks, no calendar yet), tasks + tags + rollover + snooze, daily note, Firestore + auth, notebook theme, golden-test scaffold.
2. **Daily habits** — daily questions, someday lists + pull-from-top flow, time entries.
3. **Context** — EventKit agenda, blacklist + reveal, week review templates.
4. **Reach** — macOS vault export, calendar mirror + BigMe e-ink mode, iPhone widget.

## Open questions

- Firebase project: create a fresh one for Seedling (recommended) rather than reusing an existing project's.
- Font pairing and paper texture: to be settled visually via golden prototypes in phase 1.
- Whether completed-late tasks should also show a "done Wed" marker on their originally planned day's page (currently: yes, small gray annotation).
- Daily-note templates (from the BigMe scribble: office day, meeting notes, MTG session) — a starter skeleton insertable into a day's note. Parked as a later phase; the note block stays free-form in v1.
