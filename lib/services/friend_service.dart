import '../core/constants/api_constants.dart';
import '../core/services/api_client.dart';
import '../models/friendship.dart';

class FriendService {
  final ApiClient _api;

  FriendService(this._api);

  Future<List<FriendStatus>> listFriends() async {
    final data = await _api.get(ApiConstants.friends) as List<dynamic>;
    return data.map((e) => FriendStatus.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FriendRequest>> listPending() async {
    final data = await _api.get(ApiConstants.friendsPending) as List<dynamic>;
    return data.map((e) => FriendRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FriendRequest> sendRequest(int receiverId) async {
    final data = await _api.post(ApiConstants.friendRequest(receiverId)) as Map<String, dynamic>;
    return FriendRequest.fromJson(data);
  }

  Future<FriendRequest> accept(int friendshipId) async {
    final data = await _api.post(ApiConstants.friendAccept(friendshipId)) as Map<String, dynamic>;
    return FriendRequest.fromJson(data);
  }

  Future<void> reject(int friendshipId) async {
    await _api.delete(ApiConstants.friendDelete(friendshipId));
  }
}
