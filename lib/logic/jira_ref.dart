/// A Jira ticket attached to a task.
///
/// Stored as the key alone (`MAF-1234`) plus the site it belongs to, so the
/// link can be rebuilt and the key can be shown on the tile without a URL
/// sprawling across it.
class JiraRef {
  const JiraRef({required this.key, required this.site});

  final String key;

  /// The Jira origin, e.g. `https://medappnl.atlassian.net`.
  final String site;

  String get url => '$site/browse/$key';

  Map<String, dynamic> toMap() => {'key': key, 'site': site};

  static JiraRef? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final key = map['key'] as String?;
    final site = map['site'] as String?;
    if (key == null || site == null) return null;
    return JiraRef(key: key, site: site);
  }
}

final _keyPattern = RegExp(r'^[A-Z][A-Z0-9_]*-\d+$');
final _urlPattern = RegExp(
  r'^(https?://[^/\s]+)/browse/([A-Za-z][A-Za-z0-9_]*-\d+)',
);

/// Reads what you pasted or typed into a ticket reference.
///
/// Accepts a full browse URL or a bare key. A bare key needs [defaultSite],
/// which is remembered from the last URL you pasted — typing `MAF-1234` should
/// work once Seedling knows which Jira you mean.
JiraRef? parseJiraRef(String raw, {String? defaultSite}) {
  final input = raw.trim();
  if (input.isEmpty) return null;

  final url = _urlPattern.firstMatch(input);
  if (url != null) {
    return JiraRef(key: url.group(2)!.toUpperCase(), site: url.group(1)!);
  }

  final key = input.toUpperCase();
  if (_keyPattern.hasMatch(key) && defaultSite != null && defaultSite.isNotEmpty) {
    return JiraRef(key: key, site: defaultSite);
  }
  return null;
}

/// True when [raw] looks like a key but there is no site to attach it to yet.
bool needsSiteFor(String raw, {String? defaultSite}) =>
    (defaultSite == null || defaultSite.isEmpty) &&
    _keyPattern.hasMatch(raw.trim().toUpperCase());
