import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'providers/auth_provider.dart';
import 'themes/app_theme.dart';
import 'firebase_options.dart'; // generado por flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ManosExpertasApp());
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider()..checkAuthStatus(),
      child: ManosExpertasApp(),
    ),
  );
}

class ManosExpertasApp extends StatelessWidget {
  const ManosExpertasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: AppRouter.router(context),
          );
        },
      ),
    );
  }
}
