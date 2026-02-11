import 'package:flutter/material.dart';

import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:my_business_manager/router/startup_redirect.dart'
    show StartupRedirect;
import 'package:my_business_manager/screens/admin/admin_screen.dart';
import 'package:my_business_manager/screens/admin/manage_business/manage_business.dart';
import 'package:my_business_manager/screens/admin/manage_clients/manage_clients.dart';
import 'package:my_business_manager/screens/admin/manage_notes/manage_notes.dart'
    show MyNotesScreen;
import 'package:my_business_manager/screens/admin/manage_users/admin_user_document_details_screen.dart'
    show AdminUserDocumentDetailsScreen;
import 'package:my_business_manager/screens/admin/manage_users/manage_users.dart';
import 'package:my_business_manager/screens/authentication/forgot_password.dart'
    show ForgotPasswordScreen;
import 'package:my_business_manager/screens/authentication/login_screen.dart'
    show LoginScreen;
import 'package:my_business_manager/screens/authentication/register_business_screen.dart';
import 'package:my_business_manager/screens/authentication/register_screen.dart';
import 'package:my_business_manager/screens/privacy_policy_screen.dart';
import 'package:my_business_manager/screens/shared%20screen/document_details_screen.dart'
    show DocumentDetailsScreen;
import 'package:my_business_manager/screens/users/dashboard_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/payment/success_screen.dart';

import 'navigator_key.dart';
import '../screens/admin/manage_users/admin_user_document_dashboard_screen.dart';
import '../screens/admin/company_documents/company_documents_screen.dart';

GoRouter appRouter = GoRouter(
  debugLogDiagnostics: true,
  navigatorKey: navigatorKey,
  initialLocation: StartupRedirect.getInitialRoute(Uri.base.path),

  routes: <RouteBase>[
    /// ================================
    /// PUBLIC / USER ROUTES
    /// ================================
    GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
    GoRoute(
      path: "/privacy-policy",
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),

    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: "/forgot-password",
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(
      path: '/register-business',
      builder: (_, __) => const RegisterBusinessScreen(),
    ),
    GoRoute(
      path: '/document-details',
      builder: (_, state) {
        final docType = state.uri.queryParameters["docType"]!;
        return DocumentDetailsScreen(docType: docType);
      },
    ),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/success', builder: (_, __) => const SuccessScreen()),

    /// ================================
    /// ADMIN DASHBOARD (Protected)
    /// ================================
    GoRoute(
      path: '/admin',
      builder: (_, __) {
        final profile = GetStorage().read("profile") as Map<String, dynamic>?;

        final role = profile?["role"];

        if (role == "super_admin" || role == "admin") {
          return const AdminDashboardScreen();
        }

        return const DashboardScreen(); // Unauthorized fallback
      },
    ),

    /// ================================
    /// ADMIN TOOLS (Protected by each screen)
    /// ================================
    GoRoute(
      path: '/admin/businesses',
      builder: (_, __) {
        final role = (GetStorage().read("profile") as Map?)?["role"];

        if (role == "super_admin" || role == "admin") {
          return const ManageBusinessesScreen();
        }

        return const DashboardScreen();
      },
    ),
    GoRoute(
      path: '/admin/users',
      builder: (_, __) {
        final role = (GetStorage().read("profile") as Map?)?["role"];

        if (role == "super_admin" || role == "admin") {
          return const ManageUsersScreen();
        }

        return const DashboardScreen();
      },
    ),
    GoRoute(
      path: '/admin/clients',
      builder: (_, __) {
        final role = (GetStorage().read("profile") as Map?)?["role"];

        if (role == "super_admin" || role == "admin") {
          return const ManageClientsScreen();
        }

        return const DashboardScreen();
      },
    ),
    GoRoute(
      path: '/admin/company-documents',
      builder: (_, __) {
        final role = (GetStorage().read("profile") as Map?)?["role"];

        if (role == "super_admin" || role == "admin") {
          return const CompanyDocumentsScreen();
        }

        return const DashboardScreen();
      },
    ),
    GoRoute(
      path: "/admin/user-docs",
      builder: (_, state) {
        final name = state.uri.queryParameters["name"];
        final email = state.uri.queryParameters["email"];

        if (name == null || email == null) {
          return const Scaffold(
            body: Center(child: Text("Missing user data.")),
          );
        }

        return AdminUserDocumentDashboardScreen(fullName: name, email: email);
      },
    ),

    GoRoute(
      path: "/admin/user-doc-details",
      builder: (_, state) {
        final userId = state.uri.queryParameters["userId"]!;
        final fullName = state.uri.queryParameters["fullName"]!;
        final email = state.uri.queryParameters["email"]!;
        final docType = state.uri.queryParameters["docType"]!;
        return AdminUserDocumentDetailsScreen(
          email: email,
          fullName: fullName,
          userId: userId,
          docType: docType,
        );
      },
    ),

    GoRoute(
      path: '/admin/notes',
      builder: (_, __) {
        final role = (GetStorage().read("profile") as Map?)?["role"];

        if (role == "super_admin" || role == "admin") {
          return MyNotesScreen(userId: GetStorage().read("uid"));
        }

        return const DashboardScreen();
      },
    ),
  ],
);
