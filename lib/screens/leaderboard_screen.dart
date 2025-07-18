// import 'package:flutter/material.dart';
// import 'package:simple_game_1/models/player_leaderboard_entry.dart';
// import 'package:simple_game_1/services/local_player_service.dart';
// import '../models/user_profile.dart';
// import '../models/leaderboard_entry.dart';
// import '../services/leaderboard_repository.dart';

// class LeaderboardScreen extends StatefulWidget {
//   const LeaderboardScreen({Key? key}) : super(key: key);

//   @override
//   State<LeaderboardScreen> createState() => _LeaderboardScreenState();
// }

// class _LeaderboardScreenState extends State<LeaderboardScreen> {
//   String _selectedMode = 'classic';
//   bool _friendsOnly = false;
//   late Future<List<(UserProfile, LeaderboardEntry)>> _entriesFuture;
//   PlayerLeaderboardEntry? _myRecord;

//   @override
//   void initState() {
//     super.initState();
//     _loadMyRecord();
//     _loadEntries();
//   }

//   void _loadMyRecord() async {
//     final record = await LocalPlayerService.loadMyRecord();
//     setState(() {
//       _myRecord = record;
//     });
//     if (record == null) {
//       debugPrint('🚨 No player record saved!');
//     } else {
//       debugPrint('✅ LOADED RECORD:');
//       debugPrint(' classic: ${record.classicHighScore}');
//       debugPrint(' endless: ${record.endlessHighScore}');
//       debugPrint(' levels: ${record.levelsHighestCompleted}');
//     }
//   }

//   void _loadEntries() {
//     setState(() {
//       _entriesFuture = LeaderboardRepository.getLeaderboardEntries(
//         mode: _selectedMode,
//         page: 0,
//         pageSize: 50,
//         friendsOnly: _friendsOnly,
//       );
//     });
//   }

//   Color _rankColor(int rank) {
//     switch (rank) {
//       case 0:
//         return Colors.amber;
//       case 1:
//         return Colors.grey;
//       case 2:
//         return Colors.brown;
//       default:
//         return Colors.blueGrey;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF101426),
//       appBar: AppBar(
//         title: const Text('Leaderboard'),
//         actions: [
//           IconButton(
//             icon: Icon(_friendsOnly ? Icons.group : Icons.public),
//             tooltip: _friendsOnly ? 'Friends' : 'Global',
//             onPressed: () {
//               _friendsOnly = !_friendsOnly;
//               _loadEntries();
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: ToggleButtons(
//               isSelected: [
//                 _selectedMode == 'classic',
//                 _selectedMode == 'endless',
//                 _selectedMode == 'levels',
//               ],
//               onPressed: (index) {
//                 _selectedMode = ['classic', 'endless', 'levels'][index];
//                 _loadEntries();
//               },
//               borderRadius: BorderRadius.circular(8),
//               selectedColor: Colors.white,
//               fillColor: Colors.blueAccent,
//               children: const [
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 12),
//                   child: Text('Classic'),
//                 ),
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 12),
//                   child: Text('Endless'),
//                 ),
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 12),
//                   child: Text('Levels'),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: FutureBuilder<List<(UserProfile, LeaderboardEntry)>>(
//               future: _entriesFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//                 final entries = snapshot.data ?? [];
//                 if (entries.isEmpty && _myRecord == null) {
//                   return const Center(
//                     child: Text(
//                       'No entries found.',
//                       style: TextStyle(color: Colors.white70),
//                     ),
//                   );
//                 }

//                 return ListView.separated(
//                   padding: const EdgeInsets.all(8),
//                   itemCount: entries.length + (_myRecord != null ? 1 : 0),
//                   separatorBuilder: (_, __) => const SizedBox(height: 6),
//                   itemBuilder: (context, index) {
//                     if (_myRecord != null && index == 0) {
//                       // "You" card with correct scores
//                       int score;
//                       String label;
//                       switch (_selectedMode) {
//                         case 'classic':
//                           score = _myRecord!.classicHighScore;
//                           label = 'Classic';
//                           break;
//                         case 'endless':
//                           score = _myRecord!.endlessHighScore;
//                           label = 'Endless';
//                           break;
//                         case 'levels':
//                           score = _myRecord!.levelsHighestCompleted;
//                           label = 'Levels';
//                           break;
//                         default:
//                           score = 0;
//                           label = 'Score';
//                       }
//                       return Card(
//                         color: Colors.green[800],
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: ListTile(
//                           leading: const Icon(
//                             Icons.person,
//                             color: Colors.white,
//                           ),
//                           title: Text(
//                             '${_myRecord!.username} (You)',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           subtitle: Text(
//                             '$label: $score',
//                             style: const TextStyle(color: Colors.white70),
//                           ),
//                           trailing: ClipRRect(
//                             borderRadius: BorderRadius.circular(20),
//                             child: Image.network(
//                               _myRecord!.profilePicture,
//                               width: 40,
//                               height: 40,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ),
//                       );
//                     }

//                     final adjustedIndex = _myRecord != null ? index - 1 : index;
//                     final userProfile = entries[adjustedIndex].$1;
//                     final leaderboardEntry = entries[adjustedIndex].$2;

//                     int score;
//                     String label;
//                     switch (_selectedMode) {
//                       case 'classic':
//                         score = leaderboardEntry.classicScore;
//                         label = 'Classic';
//                         break;
//                       case 'endless':
//                         score = leaderboardEntry.endlessScore;
//                         label = 'Endless';
//                         break;
//                       case 'levels':
//                         score = leaderboardEntry.highestLevelReached;
//                         label = 'Levels';
//                         break;
//                       default:
//                         score = 0;
//                         label = 'Score';
//                     }

//                     return Card(
//                       color: Colors.white10,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: _rankColor(adjustedIndex),
//                           child: Text(
//                             '#${adjustedIndex + 1}',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         title: Text(
//                           userProfile.username,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                           ),
//                         ),
//                         subtitle: Text(
//                           '$label: $score',
//                           style: const TextStyle(color: Colors.white70),
//                         ),
//                         trailing: ClipRRect(
//                           borderRadius: BorderRadius.circular(20),
//                           child: Image.network(
//                             userProfile.profileImageUrl,
//                             width: 40,
//                             height: 40,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
