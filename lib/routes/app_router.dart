import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/chat/chat_list_worker_screen.dart';

import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/login/login_screen.dart';
import '../screens/register/register_screen.dart';
import '../screens/home_client/home_client_screen.dart';
import '../screens/home_worker/home_worker_screen.dart';
import '../screens/profile/worker_profile_screen.dart';
import '../screens/profile/history/worker_history_screen.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: context.read<AuthProvider>(),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(
          path: '/homeClient',
          builder: (_, __) => const HomeClientScreen(),
        ),
        GoRoute(
          path: '/homeWorker',
          builder: (_, __) => const HomeWorkerScreen(),
        ),
        GoRoute(
          path: '/workerProfile',
          builder: (_, __) => const WorkerProfileScreen(),
        ),
        GoRoute(
          path: '/workerHistory',
          builder: (_, __) => const WorkerHistoryScreen(),
        ),
        GoRoute(path: '/chats', builder: (_, __) => const ChatListScreen()),
        GoRoute(
          path: '/chatDetail',
          builder: (context, state) {
            final nombre = state.extra as String;
            return ChatDetailScreen(nombre: nombre);
          },
        ),
        GoRoute(
          path: '/workerChats',
          builder: (_, __) => const ChatListWorkerScreen(),
        ),
      ],
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isAuth = auth.isAuthenticated;
        final isLoginOrRegister =
            state.fullPath == '/' || state.fullPath == '/register';

        if (!isAuth && !isLoginOrRegister) return '/';
        if (isAuth && isLoginOrRegister) {
          return auth.currentUser?.role == 'cliente'
              ? '/homeClient'
              : '/homeWorker';
        }
        return null;
      },
    );
  }
}
