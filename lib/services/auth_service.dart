import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  String? _userEmail;
  bool _loading = false;

  bool get isAuthenticated => _userEmail != null;
  String? get userEmail => _userEmail;
  bool get isLoading => _loading;

  Future<bool> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    // simple mock rule: if password length >= 6 accept
    if (email.isNotEmpty && password.length >= 6) {
      _userEmail = email;
      _loading = false;
      notifyListeners();
      return true;
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signup(String email, String password) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    // accept any email/password with basic checks
    if (email.contains('@') && password.length >= 6) {
      _userEmail = email;
      _loading = false;
      notifyListeners();
      return true;
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _userEmail = null;
    _loading = false;
    notifyListeners();
  }
}
