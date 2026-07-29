/// Anything shaped like a Jira key: two or more letters, a dash, digits.
///
/// Deliberately loose. It will also match `UTF-8` and `COVID-19`, and that is
/// fine — the keys are handed to Jira to look up, and whatever Jira does not
/// recognise is dropped. Guessing at project prefixes here would mean missing
/// real ones instead, which is the worse mistake for a paste-and-go screen.
final _keyPattern = RegExp(r'\b([A-Za-z][A-Za-z0-9_]{1,}-\d+)\b');

/// Every key in a blob of text, uppercased, in the order they appear and
/// without repeats.
///
/// Takes whatever you paste: a list of browse URLs, a wall of commas, a
/// standup note with keys buried in sentences.
List<String> parseJiraKeys(String text) {
  final seen = <String>{};
  for (final match in _keyPattern.allMatches(text)) {
    seen.add(match.group(1)!.toUpperCase());
  }
  return seen.toList();
}

/// The Jira origin in a pasted URL, if there is one, so the first paste can
/// teach Seedling which Jira you mean.
String? siteInText(String text) {
  final match = RegExp(r'https?://[^/\s]+\.atlassian\.net').firstMatch(text);
  return match?.group(0);
}
