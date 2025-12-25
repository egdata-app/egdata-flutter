import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/followed_game.dart';

class FollowService {
  static const String _followedGamesKey = 'followed_games';

  final StreamController<List<FollowedGame>> _followedGamesController =
      StreamController<List<FollowedGame>>.broadcast();

  Stream<List<FollowedGame>> get followedGamesStream =>
      _followedGamesController.stream;

  List<FollowedGame> _followedGames = [];
  List<FollowedGame> get followedGames => List.unmodifiable(_followedGames);

  Future<List<FollowedGame>> loadFollowedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_followedGamesKey);

    if (jsonString != null) {
      try {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        _followedGames = jsonList
            .map((json) => FollowedGame.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _followedGames = [];
      }
    } else {
      _followedGames = [];
    }

    _followedGamesController.add(_followedGames);
    return _followedGames;
  }

  Future<void> followGame(FollowedGame game) async {
    if (!isFollowing(game.offerId)) {
      _followedGames = [..._followedGames, game];
      await _saveFollowedGames();
      _followedGamesController.add(_followedGames);
    }
  }

  Future<void> unfollowGame(String offerId) async {
    _followedGames =
        _followedGames.where((game) => game.offerId != offerId).toList();
    await _saveFollowedGames();
    _followedGamesController.add(_followedGames);
  }

  bool isFollowing(String offerId) {
    return _followedGames.any((game) => game.offerId == offerId);
  }

  FollowedGame? getFollowedGame(String offerId) {
    try {
      return _followedGames.firstWhere((game) => game.offerId == offerId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveFollowedGames() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _followedGames.map((game) => game.toJson()).toList();
    await prefs.setString(_followedGamesKey, jsonEncode(jsonList));
  }

  void dispose() {
    _followedGamesController.close();
  }
}
