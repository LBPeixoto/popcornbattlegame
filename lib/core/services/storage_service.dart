import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'jwt_token';
  static const _playerIdKey = 'player_id';
  static const _usernameKey = 'username';

  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  String? get token => _prefs.getString(_tokenKey);
  int? get playerId => _prefs.getInt(_playerIdKey);
  String? get username => _prefs.getString(_usernameKey);
  bool get isLoggedIn => token != null;

  Future<void> saveSession({
    required String token,
    required int playerId,
    required String username,
  }) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setInt(_playerIdKey, playerId);
    await _prefs.setString(_usernameKey, username);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_playerIdKey);
    await _prefs.remove(_usernameKey);
  }
}
