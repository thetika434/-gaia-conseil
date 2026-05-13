class AuthState {
  static bool isLoggedIn = false;
  static bool isAdmin = false;
  static String currentUserName = '';

  static void loginAsUser(String name) {
    isLoggedIn = true;
    isAdmin = false;
    currentUserName = name;
  }

  static void loginAsAdmin(String name) {
    isLoggedIn = true;
    isAdmin = true;
    currentUserName = name;
  }

  static void logout() {
    isLoggedIn = false;
    isAdmin = false;
    currentUserName = '';
  }
}
