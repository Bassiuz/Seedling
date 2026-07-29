import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The Atlassian account Seedling logs time as.
///
/// The token lives in the keychain rather than in Firestore: it is a
/// credential for someone else's system, and a credential that syncs is a
/// credential in more places than it needs to be.
class JiraAccount {
  const JiraAccount(this._storage);

  JiraAccount.standard() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _emailKey = 'jira.email';
  static const _tokenKey = 'jira.token';

  Future<({String email, String token})?> read() async {
    final email = await _storage.read(key: _emailKey);
    final token = await _storage.read(key: _tokenKey);
    if (email == null || token == null || email.isEmpty || token.isEmpty) {
      return null;
    }
    return (email: email, token: token);
  }

  Future<void> save({required String email, required String token}) async {
    await _storage.write(key: _emailKey, value: email.trim());
    await _storage.write(key: _tokenKey, value: token.trim());
  }

  Future<void> forget() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _tokenKey);
  }
}
