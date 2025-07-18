// class UserProfile {
//   final String userId;
//   final String username;
//   final String profileImageUrl;
//   final int totalCoins;
//   final List<String> ownedCars; // e.g., ["hero1", "hero2"]
//   final List<int> ownedRoads; // e.g., [1,2,3]
//   final List<String> friendIds;

//   UserProfile({
//     required this.userId,
//     required this.username,
//     required this.profileImageUrl,
//     required this.totalCoins,
//     required this.ownedCars,
//     required this.ownedRoads,
//     required this.friendIds,
//   });

//   factory UserProfile.fromJson(Map<String, dynamic> json) {
//     return UserProfile(
//       userId: json['userId'],
//       username: json['username'],
//       profileImageUrl: json['profileImageUrl'],
//       totalCoins: json['totalCoins'],
//       ownedCars: List<String>.from(json['ownedCars'] ?? []),
//       ownedRoads: List<int>.from(json['ownedRoads'] ?? []),
//       friendIds: List<String>.from(json['friendIds'] ?? []),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'userId': userId,
//       'username': username,
//       'profileImageUrl': profileImageUrl,
//       'totalCoins': totalCoins,
//       'ownedCars': ownedCars,
//       'ownedRoads': ownedRoads,
//       'friendIds': friendIds,
//     };
//   }
// }
