import '../core/constants/api_constants.dart';
import '../core/services/api_client.dart';
import '../models/player.dart';
import '../models/player_record.dart';

class PlayerService {
  final ApiClient _api;

  PlayerService(this._api);

  Future<Player> getMe() async {
    final data = await _api.get(ApiConstants.playersMe) as Map<String, dynamic>;
    return Player.fromJson(data);
  }

  Future<Player> getById(int id) async {
    final data = await _api.get(ApiConstants.playerById(id)) as Map<String, dynamic>;
    return Player.fromJson(data);
  }

  Future<List<Player>> search(String query) async {
    final url = '${ApiConstants.playersSearch}?q=${Uri.encodeComponent(query)}';
    final data = await _api.get(url) as List<dynamic>;
    return data.map((e) => Player.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Player> updateProfile({
    String? username,
    String? email,
    String? password,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    final data = await _api.patch(ApiConstants.playersMe, body) as Map<String, dynamic>;
    return Player.fromJson(data);
  }

  Future<Player> updateVisibility({
    required bool birthdayVisible,
    required bool emailVisible,
    required bool recordsVisible,
  }) async {
    final data = await _api.patch(ApiConstants.playersMeVisibility, {
      'birthdayVisible': birthdayVisible,
      'emailVisible': emailVisible,
      'recordsVisible': recordsVisible,
    }) as Map<String, dynamic>;
    return Player.fromJson(data);
  }

  Future<PlayerRecord> getRecords(int playerId) async {
    final data = await _api.get(ApiConstants.playerRecords(playerId)) as Map<String, dynamic>;
    return PlayerRecord.fromJson(data);
  }
}
