import 'package:get_storage/get_storage.dart';

class StartupRedirect {
  static String getInitialRoute() {
    final box = GetStorage();

    final uid = box.read("uid");
    final profile = box.read("profile") as Map<String, dynamic>?;
    final role = profile?["role"];

    // Not logged in
    if (uid == null) return "/login";

    // Admin → Admin Dashboard
    if (role == "super_admin" || role == "admin") {
      return "/admin";
    }

    // Normal user → App Dashboard
    return "/";
  }
}
