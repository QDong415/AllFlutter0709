import 'package:flutter/foundation.dart';

class AccountUser {
  const AccountUser({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;
}

class Account extends ChangeNotifier {
  Account._();

  static final Account instance = Account._();

  AccountUser? _currentUser;

  AccountUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final displayName = email.split('@').first.trim();
    _currentUser = AccountUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: displayName.isEmpty ? 'User' : displayName,
      email: email.trim(),
    );
    notifyListeners();
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    _currentUser = AccountUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'User' : name.trim(),
      email: email.trim(),
    );
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
