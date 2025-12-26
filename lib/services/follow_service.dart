import 'dart:async';

import '../database/database_service.dart';
import '../models/followed_game.dart';

class FollowService {
  final DatabaseService _db;

  final StreamController<List<FollowedGame>> _followedGamesController =
      StreamController<List<FollowedGame>>.broadcast();

  Stream<List<FollowedGame>> get followedGamesStream =>
      _followedGamesController.stream;

  List<FollowedGame> _followedGames = [];
  List<FollowedGame> get followedGames => List.unmodifiable(_followedGames);

  FollowService({required DatabaseService db}) : _db = db;

  // Convert Isar entry to UI model
  FollowedGame _entryToModel(FollowedGameEntry entry) {
    return FollowedGame(
      offerId: entry.offerId,
      title: entry.title,
      namespace: entry.namespace,
      thumbnailUrl: entry.thumbnailUrl,
      followedAt: entry.followedAt,
    );
  }

  // Convert UI model to Isar entry
  FollowedGameEntry _modelToEntry(FollowedGame game) {
    return FollowedGameEntry()
      ..offerId = game.offerId
      ..title = game.title
      ..namespace = game.namespace
      ..thumbnailUrl = game.thumbnailUrl
      ..followedAt = game.followedAt;
  }

  Future<List<FollowedGame>> loadFollowedGames() async {
    final entries = await _db.getAllFollowedGames();
    _followedGames = entries.map(_entryToModel).toList();
    _followedGamesController.add(_followedGames);
    return _followedGames;
  }

  Future<void> followGame(FollowedGame game) async {
    final isAlreadyFollowing = await _db.isFollowing(game.offerId);
    if (!isAlreadyFollowing) {
      final entry = _modelToEntry(game);
      await _db.saveFollowedGame(entry);
      await _refreshFollowedGames();
    }
  }

  Future<void> unfollowGame(String offerId) async {
    await _db.deleteFollowedGame(offerId);
    await _refreshFollowedGames();
  }

  bool isFollowing(String offerId) {
    return _followedGames.any((game) => game.offerId == offerId);
  }

  Future<bool> isFollowingAsync(String offerId) async {
    return await _db.isFollowing(offerId);
  }

  FollowedGame? getFollowedGame(String offerId) {
    try {
      return _followedGames.firstWhere((game) => game.offerId == offerId);
    } catch (e) {
      return null;
    }
  }

  Future<FollowedGameEntry?> getFollowedGameEntry(String offerId) async {
    return await _db.getFollowedGameByOfferId(offerId);
  }

  Future<void> _refreshFollowedGames() async {
    final entries = await _db.getAllFollowedGames();
    _followedGames = entries.map(_entryToModel).toList();
    _followedGamesController.add(_followedGames);
  }

  void dispose() {
    _followedGamesController.close();
  }
}
