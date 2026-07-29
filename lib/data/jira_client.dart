import 'dart:convert';

import 'package:http/http.dart' as http;

import '../logic/day_key.dart';
import '../logic/worklog.dart';

/// Posts time to Jira as ordinary worklogs.
///
/// Not to Clockwork: Clockwork reports on Jira's own worklogs rather than
/// keeping its own, so writing the native ones is what makes the timesheet
/// fill in. Deliberately the v2 API — v3 wants the comment as an Atlassian
/// Document Format tree, and a sentence is a sentence.
class JiraClient {
  JiraClient({
    required this.site,
    required this.email,
    required this.apiToken,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String site;
  final String email;
  final String apiToken;
  final http.Client _http;

  Map<String, String> get _headers => {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$email:$apiToken'))}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Uri _worklogs(String issue, [String? id]) => Uri.parse(
      '$site/rest/api/2/issue/$issue/worklog${id == null ? '' : '/$id'}');

  /// Jira wants `yyyy-MM-dd'T'HH:mm:ss.SSSZ` with no colon in the offset, and
  /// rejects the ISO string Dart writes. The clock is set to mid-morning: the
  /// day is what a timesheet is about, and Seedling does not know when in it
  /// you worked.
  static String startedAt(String dayKey, {Duration offset = Duration.zero}) {
    final sign = offset.isNegative ? '-' : '+';
    final total = offset.abs();
    final hh = total.inHours.toString().padLeft(2, '0');
    final mm = (total.inMinutes % 60).toString().padLeft(2, '0');
    return '${dayKey}T09:00:00.000$sign$hh$mm';
  }

  /// Returns the new worklog's id.
  Future<String> create(WorklogAction action, {Duration? offset}) async {
    final response = await _http.post(
      _worklogs(action.jira.key),
      headers: _headers,
      body: jsonEncode(_body(action, offset)),
    );
    _check(response, 'log time on ${action.jira.key}');
    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
  }

  Future<void> update(WorklogAction action, {Duration? offset}) async {
    final response = await _http.put(
      _worklogs(action.jira.key, action.sentId!),
      headers: _headers,
      body: jsonEncode(_body(action, offset)),
    );
    _check(response, 'correct the time on ${action.jira.key}');
  }

  Future<void> delete(WorklogAction action) async {
    final response = await _http.delete(
      _worklogs(action.jira.key, action.sentId!),
      headers: _headers,
    );
    // Already gone is the state we wanted anyway.
    if (response.statusCode == 404) return;
    _check(response, 'remove the time on ${action.jira.key}');
  }

  Map<String, dynamic> _body(WorklogAction action, Duration? offset) => {
        'started': startedAt(action.dayKey,
            offset: offset ?? dateOfKey(action.dayKey).timeZoneOffset),
        'timeSpentSeconds': action.minutes * 60,
        'comment': action.title,
      };

  /// What Jira calls each of [keys]. Anything it does not recognise is simply
  /// absent from the result — which is how a loose paste gets filtered.
  Future<Map<String, String>> summaries(List<String> keys) async {
    if (keys.isEmpty) return {};
    final jql = 'key in (${keys.join(',')})';
    final response = await _http.get(
      Uri.parse('$site/rest/api/2/search').replace(queryParameters: {
        'jql': jql,
        'fields': 'summary',
        'maxResults': '${keys.length}',
        // One bad key would otherwise fail the whole query, and a paste is
        // expected to contain rubbish.
        'validateQuery': 'none',
      }),
      headers: _headers,
    );
    if (response.statusCode == 400) return {};
    _check(response, 'look those tickets up');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      for (final issue in body['issues'] as List<dynamic>? ?? const [])
        (issue as Map<String, dynamic>)['key'] as String:
            ((issue['fields'] as Map<String, dynamic>?)?['summary'] as String?) ??
                '',
    };
  }

  void _check(http.Response response, String what) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw JiraException(
      response.statusCode == 401 || response.statusCode == 403
          ? 'Jira would not accept the login. Check the email and API token.'
          : 'Could not $what (${response.statusCode}).',
    );
  }

  void close() => _http.close();
}

class JiraException implements Exception {
  const JiraException(this.message);

  final String message;

  @override
  String toString() => message;
}
