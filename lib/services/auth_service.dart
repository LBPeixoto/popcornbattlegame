import '../core/constants/api_constants.dart';
import '../core/services/api_client.dart';
import '../core/services/storage_service.dart';
import '../models/auth_response.dart';

class AuthService {
  final ApiClient _api;
  final StorageService _storage;

  AuthService(this._api, this._storage);

  Future<AuthResponse> login(String login, String password) async {
    final data = await _api.post(ApiConstants.login, body: {
      'login': login,
      'password': password,
    }) as Map<String, dynamic>;
    final response = AuthResponse.fromJson(data);
    await _storage.saveSession(
      token: response.token,
      playerId: response.player.id,
      username: response.player.username,
    );
    return response;
  }

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    required String birthday,
  }) async {
    final data = await _api.post(ApiConstants.register, body: {
      'username': username,
      'email': email,
      'password': password,
      'birthday': birthday,
    }) as Map<String, dynamic>;
    final response = AuthResponse.fromJson(data);
    await _storage.saveSession(
      token: response.token,
      playerId: response.player.id,
      username: response.player.username,
    );
    return response;
  }

  Future<void> logout() => _storage.clearSession();
}
