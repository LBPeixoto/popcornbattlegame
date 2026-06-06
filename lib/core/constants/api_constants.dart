class ApiConstants {
  static const String baseUrl = 'http://192.168.15.26:8080/api';

  // Auth
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';

  // Players
  static const String playersMe = '$baseUrl/players/me';
  static const String playersSearch = '$baseUrl/players/search';
  static String playerById(int id) => '$baseUrl/players/$id';

  // Friends
  static const String friends = '$baseUrl/friends';
  static const String friendsPending = '$baseUrl/friends/pending';
  static String friendRequest(int receiverId) => '$baseUrl/friends/request/$receiverId';
  static String friendAccept(int friendshipId) => '$baseUrl/friends/accept/$friendshipId';
  static String friendDelete(int friendshipId) => '$baseUrl/friends/$friendshipId';

  // Challenges
  static const String challenges = '$baseUrl/challenges';
  static String challengeById(int id) => '$baseUrl/challenges/$id';
  static String roundDraw(int challengeId, int n) => '$baseUrl/challenges/$challengeId/rounds/$n/draw';
  static String roundQuestions(int challengeId, int n) => '$baseUrl/challenges/$challengeId/rounds/$n/questions';
  static String roundAttempt(int challengeId, int n) => '$baseUrl/challenges/$challengeId/rounds/$n/attempt';

  // Player profile & privacy
  static const String playersMeVisibility = '$baseUrl/players/me/visibility';
  static String playerRecords(int id) => '$baseUrl/players/$id/records';

  // Themes
  static const String themes = '$baseUrl/themes';

  // Tickets
  static const String buyTicketWithCoins = '$baseUrl/tickets/purchase';

  // Suggestions
  static const String suggestMc = '$baseUrl/suggestions/multiple-choice';
  static const String suggestTf = '$baseUrl/suggestions/true-false';
  static const String suggestOrdering = '$baseUrl/suggestions/ordering';
  static const String suggestList = '$baseUrl/suggestions/list';
}
