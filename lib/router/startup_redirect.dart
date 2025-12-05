import 'package:get_storage/get_storage.dart';

class StartupRedirect {
  static String getInitialRoute(String location) {
    final box = GetStorage();

    // PUBLIC PAGES (no authentication required)
    const publicRoutes = {
      '/privacy-policy',
      '/login',
      '/register',
      '/register-business',
      '/forgot-password',
    };

    // If user navigates to a public route → always allow it.
    if (publicRoutes.contains(location)) {
      return location;
    }

    // 🔐 Check user login
    final uid = box.read("uid");
    final profile = box.read("profile") as Map<String, dynamic>?;
    final role = profile?["role"];

    if (uid == null) return "/login";

    // Admin → Admin Dashboard
    if (role == "super_admin" || role == "admin") {
      return "/admin";
    }

    return "/";
  }
}
