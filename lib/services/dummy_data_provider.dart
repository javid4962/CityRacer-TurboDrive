// import 'dart:math';
// import '../models/user_profile.dart';
// import '../models/leaderboard_entry.dart';

// class DummyDataProvider {
//   static final _rand = Random();

//   /// Simulated dummy user profiles
//   static final List<UserProfile> _dummyUsers = List.generate(100, (i) {
//     return UserProfile(
//       userId: 'user_$i',
//       username: 'Player $i',
//       profileImageUrl:
//           'https://i.pravatar.cc/150?img=${i % 70}', // Random avatar
//       totalCoins: _rand.nextInt(10000),
//       ownedCars: List.generate(
//         _rand.nextInt(3) + 1,
//         (index) => 'hero${index + 1}',
//       ),
//       ownedRoads: List.generate(_rand.nextInt(3) + 1, (index) => index + 1),
//       friendIds: List.generate(
//         _rand.nextInt(5),
//         (index) => 'user_${_rand.nextInt(100)}',
//       ),
//     );
//   });

//   /// Simulated leaderboard entries
//   static final Map<String, List<LeaderboardEntry>> _dummyEntries = {
//     'classic': List.generate(
//       100,
//       (_) => LeaderboardEntry(
//         classicScore: _rand.nextInt(5000),
//         endlessScore: _rand.nextInt(3000),
//         highestLevelReached: _rand.nextInt(100),
//       ),
//     ),
//     'endless': List.generate(
//       100,
//       (_) => LeaderboardEntry(
//         classicScore: _rand.nextInt(5000),
//         endlessScore: _rand.nextInt(3000),
//         highestLevelReached: _rand.nextInt(100),
//       ),
//     ),
//     'levels': List.generate(
//       100,
//       (_) => LeaderboardEntry(
//         classicScore: _rand.nextInt(5000),
//         endlessScore: _rand.nextInt(3000),
//         highestLevelReached: _rand.nextInt(100),
//       ),
//     ),
//   };

//   static Future<List<(UserProfile, LeaderboardEntry)>> fetchPage({
//     required String mode,
//     required int page,
//     required int pageSize,
//     required bool friendsOnly,
//     required String currentUserId,
//   }) async {
//     await Future.delayed(const Duration(milliseconds: 500)); // Simulate latency

//     final start = page * pageSize;
//     final end = start + pageSize;

//     List<int> indices = List.generate(_dummyUsers.length, (i) => i);

//     if (friendsOnly) {
//       final currentUser = _dummyUsers.firstWhere(
//         (u) => u.userId == currentUserId,
//         orElse: () => _dummyUsers[0],
//       );
//       indices = _dummyUsers
//           .where((u) => currentUser.friendIds.contains(u.userId))
//           .map((u) => _dummyUsers.indexOf(u))
//           .toList();
//     }

//     final selected = indices.skip(start).take(pageSize).toList();

//     return selected.map((i) {
//       return (_dummyUsers[i], _dummyEntries[mode]![i]);
//     }).toList();
//   }
// }
