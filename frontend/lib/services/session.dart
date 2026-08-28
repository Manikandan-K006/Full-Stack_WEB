import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';

/// Central authentication state. Exposes login/register/logout and a
/// ChangeNotifier that the UI listens to for navigation decisions.
class Session extends ChangeNotifier {
  User? _user;
  bool _restoring = true;
  bool get restoring => _restoring;
  User? get user => _user;
  bool get isAuthenticated => _user != null && ApiClient.instance.hasToken;

  Future<void> restore() async {
    final token = await TokenStorage.getToken();
    final userJson = await TokenStorage.getUser();
    if (token != null && userJson != null) {
      ApiClient.instance.token = token;
      _user = User.fromJson(userJson);
    }
    _restoring = false;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    final data = await ApiClient.instance
        .post('/api/auth/register', body: {'name': name, 'email': email, 'password': password});
    await _accept(data);
  }

  Future<void> login(String email, String password) async {
    final data = await ApiClient.instance
        .post('/api/auth/login', body: {'email': email, 'password': password});
    await _accept(data);
  }

  Future<void> _accept(dynamic data) async {
    final token = (data as Map<String, dynamic>)['token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;
    ApiClient.instance.token = token;
    _user = User.fromJson(userJson);
    await TokenStorage.saveSession(token, userJson);
    notifyListeners();
  }

  Future<void> logout() async {
    ApiClient.instance.token = '';
    _user = null;
    await TokenStorage.clear();
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? bio}) async {
    final updated = await ApiClient.instance
        .put('/api/users/me', body: {'name': name, 'bio': bio});
    _user = User.fromJson(updated as Map<String, dynamic>);
    await TokenStorage.saveSession(ApiClient.instance.token, _user!.toJson());
    notifyListeners();
  }
}
