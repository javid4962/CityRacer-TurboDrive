// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dummy_data_provider.dart';
// import '../models/user_profile.dart';
// import '../models/leaderboard_entry.dart';
// import '../models/player_leaderboard_entry.dart';
// import 'local_player_service.dart';

// class LeaderboardRepository {
//   static Future<List<(UserProfile, LeaderboardEntry)>> getLeaderboardEntries({
//     required String mode,
//     required int page,
//     required int pageSize,
//     required bool friendsOnly,
//   }) async {
//     // 1️⃣ Load dummy entries for the page
//     final dummyEntries = await DummyDataProvider.fetchPage(
//       mode: mode,
//       page: page,
//       pageSize: pageSize,
//       friendsOnly: friendsOnly,
//       currentUserId: 'you',
//     );

//     // 2️⃣ Load your saved player record
//     final PlayerLeaderboardEntry? myRecord =
//         await LocalPlayerService.loadMyRecord();

//     if (myRecord == null) {
//       // No saved record, return only dummy entries
//       return dummyEntries;
//     }

//     // 3️⃣ Convert PlayerLeaderboardEntry to UserProfile + LeaderboardEntry
//     final UserProfile myProfile = UserProfile(
//       userId: myRecord.userId,
//       username: myRecord.username,
//       profileImageUrl: myRecord.profilePicture,
//       totalCoins: myRecord.totalCoins,
//       ownedCars: myRecord.ownedCars,
//       ownedRoads: myRecord.ownedRoads,
//       friendIds: myRecord.friendIds,
//     );

//     final LeaderboardEntry myLeaderboardEntry = LeaderboardEntry(
//       classicScore: myRecord.classicHighScore,
//       endlessScore: myRecord.endlessHighScore,
//       highestLevelReached: myRecord.levelsHighestCompleted,
//     );

//     final myTuple = (myProfile, myLeaderboardEntry);

//     // 4️⃣ Combine your entry with dummy entries
//     final List<(UserProfile, LeaderboardEntry)> allEntries = [
//       ...dummyEntries,
//       myTuple,
//     ];

//     // 5️⃣ Sort descending by the mode's score
//     allEntries.sort((a, b) {
//       int scoreA = _getScoreByMode(a.$2, mode);
//       int scoreB = _getScoreByMode(b.$2, mode);
//       return scoreB.compareTo(scoreA);
//     });

//     return allEntries;
//   }

//   static int _getScoreByMode(LeaderboardEntry entry, String mode) {
//     switch (mode) {
//       case 'classic':
//         return entry.classicScore;
//       case 'endless':
//         return entry.endlessScore;
//       case 'levels':
//         return entry.highestLevelReached;
//       default:
//         return 0;
//     }
//   }
  
//   Future<List<LeaderboardEntry>> fetchLocalLeaderboard() async {
//   final box = await Hive.openBox('playerBox');
//   final classicHighScore = box.get('classicHighScore', defaultValue: 0);
//   final endlessHighScore = box.get('endlessHighScore', defaultValue: 0);
//   final highestLevel = box.get('levelsHighestCompleted', defaultValue: 0);

//   final entry = LeaderboardEntry(
//     classicScore: classicHighScore,
//     endlessScore: endlessHighScore,
//     highestLevelReached: highestLevel,
//   );

//   return [entry];
// }



// }
