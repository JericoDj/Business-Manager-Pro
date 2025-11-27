import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigator_key.dart';
import 'providers/auth_provider.dart';


class AuthRefresh extends ChangeNotifier {
  AuthRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final auth = Provider.of<AuthProvider>(context, listen: false);

        // When AuthProvider notifies, refresh GoRouter
        auth.addListener(() {
          notifyListeners();
        });
      }
    });
  }
}
