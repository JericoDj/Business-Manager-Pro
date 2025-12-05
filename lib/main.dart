
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_business_manager/providers/client_provider.dart' show ClientProvider;
import 'package:my_business_manager/providers/document_provider.dart' show DocumentProvider;
import 'package:my_business_manager/providers/manage_user_provider.dart' show ManageUserProvider;
import 'package:my_business_manager/utils/my_colors.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();   // ← MUST come first
  //
  // if (!kIsWeb) {
  //   await dotenv.load(fileName: ".env"); // Only mobile
  // }     // ← NOW loads correctly

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCCzxcJ0OCgl5oe-n6S-73lgE1TGMqKcyU",
        appId: "1:404595228914:web:5a5baa60241aac53db106b",
        messagingSenderId: "404595228914",
        projectId: "dignity-with-care",
        storageBucket: "dignity-with-care.firebasestorage.app",
        authDomain: "dignity-with-care.firebaseapp.com",
        measurementId: "G-FQ18C33WQE",
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await GetStorage.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => ManageUserProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        // ChangeNotifierProvider(create: (_) => NotesProvider()),


      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primaryColor: MyColors.darkShade,
        scaffoldBackgroundColor: MyColors.softWhite,

        colorScheme: ColorScheme.fromSeed(
          seedColor: MyColors.darkShade,
          primary: MyColors.darkShade,
          secondary: MyColors.accent,
          background: MyColors.lightShade,
        ),

        // ---------------------------
        // GLOBAL GOOGLE FONTS (ROBOTO)
        // ---------------------------
        textTheme: GoogleFonts.notoSerifJpTextTheme().copyWith(
          titleLarge: GoogleFonts.notoSerifJp(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: GoogleFonts.notoSerifJp(fontSize: 16),
          bodyMedium: GoogleFonts.notoSerifJp(fontSize: 14),
        ),

        // ---------------------------
        // TEXTFIELD THEMES USING ROBOTO
        // ---------------------------
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: GoogleFonts.notoSerifJp(
            fontSize: 14,
          ),
          hintStyle: GoogleFonts.notoSerifJp(
            fontSize: 14,
            color: Colors.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        // BUTTON TEXTS ALSO USE ROBOTO
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.sourceCodePro(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      routerConfig: appRouter,
    );
  }
}

