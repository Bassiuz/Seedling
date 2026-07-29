import '../logic/jira_ref.dart';

/// A Jira ticket Seedling knows about, and when you last put something on it.
///
/// The list exists so tagging is a tap rather than a search: the ones you
/// touched this morning are the ones you will touch again this afternoon.
class JiraTicket {
  const JiraTicket({
    required this.key,
    required this.site,
    this.summary,
    this.lastUsed,
  });

  final String key;
  final String site;

  /// What Jira calls it. Null until a lookup has happened.
  final String? summary;

  /// When it was last tagged onto something. Null for one that has only been
  /// imported, which sorts it below anything you have actually used.
  final DateTime? lastUsed;

  JiraRef get ref => JiraRef(key: key, site: site);

  factory JiraTicket.fromMap(String id, Map<String, dynamic> map) => JiraTicket(
        key: map['key'] as String? ?? id,
        site: map['site'] as String? ?? '',
        summary: map['summary'] as String?,
        lastUsed: DateTime.tryParse(map['lastUsed'] as String? ?? ''),
      );

  Map<String, dynamic> toMap() => {
        'key': key,
        'site': site,
        'summary': summary,
        'lastUsed': lastUsed?.toIso8601String(),
      };

  /// Most recently used first; never used at all comes last, alphabetically
  /// so an imported batch reads in an order that makes sense.
  static int byRecency(JiraTicket a, JiraTicket b) {
    if (a.lastUsed == null && b.lastUsed == null) return a.key.compareTo(b.key);
    if (a.lastUsed == null) return 1;
    if (b.lastUsed == null) return -1;
    return b.lastUsed!.compareTo(a.lastUsed!);
  }
}
