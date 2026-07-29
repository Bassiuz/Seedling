import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/jira_keys.dart';

void main() {
  group('parseJiraKeys', () {
    test('reads a plain list, however it is separated', () {
      expect(parseJiraKeys('AT-1234, MAF-99\nAT-7  AT-8;MAF-1'),
          ['AT-1234', 'MAF-99', 'AT-7', 'AT-8', 'MAF-1']);
    });

    test('digs them out of browse URLs', () {
      expect(
        parseJiraKeys('''
          https://example.atlassian.net/browse/AT-4496
          https://example.atlassian.net/jira/software/projects/MAF/boards/3?selectedIssue=MAF-4319
        '''),
        ['AT-4496', 'MAF-4319'],
      );
    });

    test('finds them in the middle of a sentence', () {
      expect(parseJiraKeys('Did AT-1 today, then started on MAF-22.'),
          ['AT-1', 'MAF-22']);
    });

    test('keeps the order they appeared in and drops repeats', () {
      expect(parseJiraKeys('MAF-2 AT-1 MAF-2 AT-1'), ['MAF-2', 'AT-1']);
    });

    test('uppercases what was typed in lower case', () {
      expect(parseJiraKeys('at-1234'), ['AT-1234']);
    });

    test('nothing in, nothing out', () {
      expect(parseJiraKeys(''), isEmpty);
      expect(parseJiraKeys('no tickets here at all'), isEmpty);
    });

    test('a date is not a ticket', () {
      // The digits come first, so it cannot match — worth pinning, because
      // day keys are all over this app.
      expect(parseJiraKeys('2026-07-29'), isEmpty);
    });

    test('a single letter is not enough', () {
      expect(parseJiraKeys('A-1'), isEmpty);
    });

    test('junk that looks like a key is left for Jira to reject', () {
      // Better than guessing at project prefixes and dropping a real one.
      expect(parseJiraKeys('encoded as UTF-8'), ['UTF-8']);
    });
  });

  group('siteInText', () {
    test('learns the Jira from a pasted link', () {
      expect(siteInText('see https://example.atlassian.net/browse/AT-1'),
          'https://example.atlassian.net');
    });

    test('bare keys teach it nothing', () {
      expect(siteInText('AT-1, AT-2'), isNull);
    });
  });
}
