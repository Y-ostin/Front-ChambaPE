import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/worker_provider.dart';
import 'providers/nestjs_provider.dart';
import 'providers/offers_provider.dart';
import 'themes/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => WorkerProvider()),
        ChangeNotifierProvider(create: (context) => NestJSProvider()),
        ChangeNotifierProvider(create: (context) => OffersProvider()),
      ],
      child: const ChambaPEApp(),
    ),
  );
}

class ChambaPEApp extends StatefulWidget {
  const ChambaPEApp({super.key});

  @override
  State<ChambaPEApp> createState() => _ChambaPEAppState();
}

class _ChambaPEAppState extends State<ChambaPEApp> {
  @override
  void initState() {
    super.initState();
    // Inicializar deep links después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.initialize(context);
    });
  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: languageProvider.locale,
          supportedLocales: languageProvider.supportedLocales.values.toList(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: AppRouter.router(context),
        );
      },
    );
  }
}
