import '../core/constants/api_constants.dart';
import '../core/services/api_client.dart';
import '../models/player.dart';

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
}
