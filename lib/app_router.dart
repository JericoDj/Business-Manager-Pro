import 'package:dignitywithcare/screens/document_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import 'app_router_refresh.dart';
import 'navigator_key.dart';

GoRouter appRouter = GoRouter(
  debugLogDiagnostics: true,
  navigatorKey: navigatorKey,
  // 👇 VERY IMPORTANT — tells GoRouter to refresh when AuthProvider notifies
  refreshListenable: AuthRefresh(),

  redirect: (context, state) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (!auth.initialized) return null;

    final loggedIn = auth.isLoggedIn;

    final isAuthRoute =
        state.matchedLocation == "/login" ||
            state.matchedLocation == "/register";

    if (!loggedIn && !isAuthRoute) {
      return "/login";
    }

    if (loggedIn && isAuthRoute) {
      return "/";
    }

    return null;
  },

  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/document-details',
      builder: (_, state) {
        final docType = state.uri.queryParameters["docType"]!;
        return DocumentDetailsScreen(docType: docType);
      },
    ),
  ],
);
