import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seedling/data/jira_client.dart';
import 'package:seedling/logic/jira_ref.dart';
import 'package:seedling/logic/worklog.dart';

const _site = 'https://example.atlassian.net';
const _day = '2026-07-28';

WorklogAction _action({
  WorklogVerb verb = WorklogVerb.create,
  int minutes = 90,
  String? sentId,
}) =>
    WorklogAction(
      verb: verb,
      jira: const JiraRef(key: 'MAF-1', site: _site),
      dayKey: _day,
      minutes: minutes,
      title: 'Fix the export',
      key: 't@$_day',
      sentId: sentId,
    );

JiraClient _client(MockClient mock) => JiraClient(
      site: _site,
      email: 'you@example.com',
      apiToken: 'secret',
      httpClient: mock,
    );

void main() {
  group('started', () {
    test('is the shape Jira insists on, offset without a colon', () {
      expect(JiraClient.startedAt(_day, offset: const Duration(hours: 2)),
          '2026-07-28T09:00:00.000+0200');
    });

    test('handles a negative offset and a half hour', () {
      expect(
          JiraClient.startedAt(_day, offset: const Duration(hours: -3, minutes: -30)),
          '2026-07-28T09:00:00.000-0330');
    });

    test('UTC reads as +0000, not Z', () {
      expect(JiraClient.startedAt(_day), '2026-07-28T09:00:00.000+0000');
    });
  });

  test('creating posts the minutes as seconds and returns the id', () async {
    late http.Request sent;
    final client = _client(MockClient((request) async {
      sent = request;
      return http.Response(jsonEncode({'id': '10123'}), 201);
    }));

    final id = await client.create(_action(), offset: Duration.zero);

    expect(id, '10123');
    expect(sent.method, 'POST');
    expect(sent.url.path, '/rest/api/2/issue/MAF-1/worklog');
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['timeSpentSeconds'], 5400);
    expect(body['comment'], 'Fix the export');
    expect(body['started'], '2026-07-28T09:00:00.000+0000');
  });

  test('the token travels as basic auth, not in the body', () async {
    late http.Request sent;
    final client = _client(MockClient((request) async {
      sent = request;
      return http.Response(jsonEncode({'id': '1'}), 201);
    }));

    await client.create(_action(), offset: Duration.zero);

    expect(sent.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('you@example.com:secret'))}');
    expect(sent.body, isNot(contains('secret')));
  });

  test('updating puts to the worklog that is already there', () async {
    late http.Request sent;
    final client = _client(MockClient((request) async {
      sent = request;
      return http.Response('{}', 200);
    }));

    await client.update(
        _action(verb: WorklogVerb.update, minutes: 120, sentId: '10123'),
        offset: Duration.zero);

    expect(sent.method, 'PUT');
    expect(sent.url.path, '/rest/api/2/issue/MAF-1/worklog/10123');
    expect(jsonDecode(sent.body)['timeSpentSeconds'], 7200);
  });

  test('deleting removes it', () async {
    late http.Request sent;
    final client = _client(MockClient((request) async {
      sent = request;
      return http.Response('', 204);
    }));

    await client.delete(_action(verb: WorklogVerb.delete, sentId: '10123'));

    expect(sent.method, 'DELETE');
    expect(sent.url.path, '/rest/api/2/issue/MAF-1/worklog/10123');
  });

  test('a worklog already gone is not an error', () async {
    final client = _client(MockClient((_) async => http.Response('', 404)));

    await client.delete(_action(verb: WorklogVerb.delete, sentId: '10123'));
  });

  test('a refused login says so in words rather than a number', () async {
    final client = _client(MockClient((_) async => http.Response('nope', 401)));

    expect(
      () => client.create(_action()),
      throwsA(isA<JiraException>().having(
          (e) => e.message, 'message', contains('email and API token'))),
    );
  });

  test('any other failure names what it was doing', () async {
    final client = _client(MockClient((_) async => http.Response('', 500)));

    expect(
      () => client.create(_action()),
      throwsA(isA<JiraException>()
          .having((e) => e.message, 'message', contains('MAF-1'))),
    );
  });
}
