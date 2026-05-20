import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  static bool isLoggedIn = false;
  static bool isAdmin = false;
  static String currentUserName = '';
  static String? currentUserId;

  static void loginAsUser({required String name, required String userId}) {
    isLoggedIn = true;
    isAdmin = false;
    currentUserName = name;
    currentUserId = userId;
  }

  static void loginAsAdmin({required String name, required String userId}) {
    isLoggedIn = true;
    isAdmin = true;
    currentUserName = name;
    currentUserId = userId;
  }

  static void logout() {
    Supabase.instance.client.auth.signOut(); // fire-and-forget
    isLoggedIn = false;
    isAdmin = false;
    currentUserName = '';
    currentUserId = null;
  }
}
