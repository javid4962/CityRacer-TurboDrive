// lib/services/local_player_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_leaderboard_entry.dart';

class LocalPlayerService {
  static const String _key = 'my_player_record';

  /// Save or update the player's record while preserving historical highs.
  static Future<void> saveMyRecord(PlayerLeaderboardEntry entry) async {
    final prefs = await SharedPreferences.getInstance();

    final oldJsonStr = prefs.getString(_key);
    if (oldJsonStr != null) {
      final existing = PlayerLeaderboardEntry.fromJson(jsonDecode(oldJsonStr));

      // Build merged record
      entry = PlayerLeaderboardEntry(
        userId: entry.userId.isNotEmpty ? entry.userId : existing.userId,
        username: entry.username.isNotEmpty
            ? entry.username
            : existing.username,
        profilePicture: entry.profilePicture.isNotEmpty
            ? entry.profilePicture
            : existing.profilePicture,
        totalCoins: entry.totalCoins >= existing.totalCoins
            ? entry.totalCoins
            : existing.totalCoins,
        classicHighScore: entry.classicHighScore >= existing.classicHighScore
            ? entry.classicHighScore
            : existing.classicHighScore,
        endlessHighScore: entry.endlessHighScore >= existing.endlessHighScore
            ? entry.endlessHighScore
            : existing.endlessHighScore,
        levelsHighestCompleted:
            entry.levelsHighestCompleted >= existing.levelsHighestCompleted
            ? entry.levelsHighestCompleted
            : existing.levelsHighestCompleted,
        ownedCars: entry.ownedCars.isNotEmpty
            ? entry.ownedCars
            : existing.ownedCars,
        ownedRoads: entry.ownedRoads.isNotEmpty
            ? entry.ownedRoads
            : existing.ownedRoads,
        friendIds: entry.friendIds.isNotEmpty
            ? entry.friendIds
            : existing.friendIds,
      );
    }

    final jsonStr = jsonEncode(entry.toJson());
    await prefs.setString(_key, jsonStr);
  }

  /// Load the saved player record.
  static Future<PlayerLeaderboardEntry?> loadMyRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return null;
    return PlayerLeaderboardEntry.fromJson(jsonDecode(jsonStr));
  }

  /// Helper to create a fresh new record.
  static PlayerLeaderboardEntry createRecord({
    required String username,
    required String profilePic,
    required int coins,
    required int classicScore,
    required int endlessScore,
    required int highestLevel,
    required List<String> ownedCars,
    required List<int> ownedRoads,
    List<String>? friendIds, // optional
  }) {
    return PlayerLeaderboardEntry(
      userId: 'you',
      username: username,
      profilePicture: profilePic,
      totalCoins: coins,
      classicHighScore: classicScore,
      endlessHighScore: endlessScore,
      levelsHighestCompleted: highestLevel,
      ownedCars: ownedCars,
      ownedRoads: ownedRoads,
      friendIds: friendIds ?? [],
    );
  }
}
