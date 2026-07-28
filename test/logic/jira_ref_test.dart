import 'package:flutter_test/flutter_test.dart';
import 'package:seedling/logic/jira_ref.dart';

const _site = 'https://medappnl.atlassian.net';

void main() {
  group('a pasted URL', () {
    test('gives both the key and the site', () {
      final ref = parseJiraRef('$_site/browse/AT-4593');

      expect(ref!.key, 'AT-4593');
      expect(ref.site, _site);
      expect(ref.url, '$_site/browse/AT-4593');
    });

    test('survives the trailing rubbish Jira adds to a link', () {
      final ref = parseJiraRef('$_site/browse/MAF-1234?focusedId=99#comment');

      expect(ref!.key, 'MAF-1234');
      expect(ref.url, '$_site/browse/MAF-1234',
          reason: 'the link is rebuilt clean');
    });

    test('needs no default site of its own', () {
      expect(parseJiraRef('$_site/browse/AT-1')!.site, _site);
    });
  });

  group('a bare key', () {
    test('works once Seedling knows which Jira you mean', () {
      final ref = parseJiraRef('MAF-1234', defaultSite: _site);

      expect(ref!.key, 'MAF-1234');
      expect(ref.site, _site);
    });

    test('is accepted in lower case', () {
      expect(parseJiraRef('maf-1234', defaultSite: _site)!.key, 'MAF-1234');
    });

    test('is refused when there is no site yet', () {
      expect(parseJiraRef('MAF-1234'), isNull);
      expect(needsSiteFor('MAF-1234'), isTrue,
          reason: 'so the UI can say what is missing');
      expect(needsSiteFor('MAF-1234', defaultSite: _site), isFalse);
    });
  });

  group('things that are not tickets', () {
    test('plain words and empty input', () {
      expect(parseJiraRef('', defaultSite: _site), isNull);
      expect(parseJiraRef('   ', defaultSite: _site), isNull);
      expect(parseJiraRef('lunch with Rik', defaultSite: _site), isNull);
    });

    test('a key without a number, or a number without a key', () {
      expect(parseJiraRef('MAF-', defaultSite: _site), isNull);
      expect(parseJiraRef('-1234', defaultSite: _site), isNull);
      expect(parseJiraRef('1234', defaultSite: _site), isNull);
    });

    test('some other Atlassian page', () {
      expect(parseJiraRef('$_site/jira/software/projects/MAF/boards/1'), isNull);
    });
  });

  group('storing it', () {
    test('survives a round trip', () {
      const ref = JiraRef(key: 'AT-4593', site: _site);

      final back = JiraRef.fromMap(ref.toMap());

      expect(back!.key, 'AT-4593');
      expect(back.site, _site);
    });

    test('a missing or half-written map is no reference at all', () {
      expect(JiraRef.fromMap(null), isNull);
      expect(JiraRef.fromMap(const {'key': 'AT-1'}), isNull);
      expect(JiraRef.fromMap(const {}), isNull);
    });
  });
}
