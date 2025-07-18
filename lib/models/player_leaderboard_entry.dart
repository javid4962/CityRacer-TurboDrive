// lib/game/models/player_leaderboard_entry.dart
import 'package:flutter/foundation.dart';

@immutable
class PlayerLeaderboardEntry {
  final String userId;
  final String username;
  final String profilePicture;
  final int totalCoins;
  final int classicHighScore;
  final int endlessHighScore;
  final int levelsHighestCompleted;
  final List<String> ownedCars;
  final List<int> ownedRoads;
  final List<String> friendIds;

  const PlayerLeaderboardEntry({
    required this.userId,
    required this.username,
    required this.profilePicture,
    required this.totalCoins,
    required this.classicHighScore,
    required this.endlessHighScore,
    required this.levelsHighestCompleted,
    required this.ownedCars,
    required this.ownedRoads,
    required this.friendIds,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'profilePicture': profilePicture,
    'totalCoins': totalCoins,
    'classicHighScore': classicHighScore,
    'endlessHighScore': endlessHighScore,
    'levelsHighestCompleted': levelsHighestCompleted,
    'ownedCars': ownedCars,
    'ownedRoads': ownedRoads,
    'friendIds': friendIds,
  };

  factory PlayerLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return PlayerLeaderboardEntry(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profilePicture: json['profilePicture'] as String? ?? '',
      totalCoins: json['totalCoins'] as int? ?? 0,
      classicHighScore: json['classicHighScore'] as int? ?? 0,
      endlessHighScore: json['endlessHighScore'] as int? ?? 0,
      levelsHighestCompleted: json['levelsHighestCompleted'] as int? ?? 0,
      ownedCars: List<String>.from(json['ownedCars'] ?? []),
      ownedRoads: List<int>.from(json['ownedRoads'] ?? []),
      friendIds: List<String>.from(json['friendIds'] ?? []),
    );
  }
}
