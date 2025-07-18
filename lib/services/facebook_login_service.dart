// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

// class FacebookLoginService {
//   static AccessToken? _accessToken;
//   static Map<String, dynamic>? _userData;

//   static bool get isLoggedIn => _accessToken != null;

//   static Future<bool> login() async {
//     final result = await FacebookAuth.instance.login();
//     if (result.status == LoginStatus.success) {
//       _accessToken = result.accessToken;
//       _userData = await FacebookAuth.instance.getUserData(
//         fields: "id,name,email,picture.width(200)",
//       );
//       return true;
//     }
//     return false;
//   }

//   static Future<void> logout() async {
//     await FacebookAuth.instance.logOut();
//     _accessToken = null;
//     _userData = null;
//   }

//   static String? get userName => _userData?['name'] as String?;
//   static String? get userEmail => _userData?['email'] as String?;
//   static String? get profilePictureUrl =>
//       (_userData?['picture'] as Map?)?['data']?['url'] as String?;
// }
