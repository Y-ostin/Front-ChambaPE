import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/chat/chat_list_worker_screen.dart';

import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/nestjs_provider.dart';
import '../screens/login/login_screen.dart';
import '../screens/register/register_screen.dart';
import '../screens/auth/login_screen_new.dart';
import '../screens/auth/register_screen_new.dart';
import '../screens/home_client/home_client_screen.dart';
import '../screens/home_worker/home_worker_screen.dart';
import '../screens/profile/worker_profile_screen.dart';
import '../screens/profile/history/worker_history_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/complete_worker_registration_screen.dart';
import '../screens/auth/complete_worker_profile_screen.dart';
import '../screens/worker/worker_availability_screen.dart';
import '../screens/worker/worker_complete_profile_screen.dart';
import '../screens/worker/worker_dashboard_screen.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: context.read<AuthProvider>(),
      routes: [
        // Rutas de autenticación
        GoRoute(
          path: '/login', 
          builder: (_, __) => const LoginScreenNew(),
        ),
        GoRoute(
          path: '/register', 
          builder: (_, __) => const RegisterScreenNew(),
        ),
        
        // Rutas de dashboard
        GoRoute(
          path: '/client/dashboard',
          builder: (_, __) => const HomeClientScreen(),
        ),
        GoRoute(
          path: '/worker/dashboard',
          builder: (_, __) => const WorkerDashboardScreen(),
        ),
        
        // Rutas de perfil
        GoRoute(
          path: '/worker/profile',
          builder: (_, __) => const WorkerProfileScreen(),
        ),
        GoRoute(
          path: '/worker/history',
          builder: (_, __) => const WorkerHistoryScreen(),
        ),
        
        // Rutas de chat
        GoRoute(
          path: '/chats', 
          builder: (_, __) => const ChatListScreen(),
        ),
        GoRoute(
          path: '/worker/chats',
          builder: (_, __) => const ChatListWorkerScreen(),
        ),
        GoRoute(
          path: '/chat/detail',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return ChatDetailScreen(
              conversationId: extra['conversationId'],
              otherUserName: extra['otherUserName'],
              otherUserId: extra['otherUserId'],
            );
          },
        ),
        
        // Rutas de configuración
        GoRoute(
          path: '/settings', 
          builder: (_, __) => const SettingsScreen(),
        ),
        
        // Rutas de verificación
        GoRoute(
          path: '/email-verification',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return EmailVerificationScreen(
              email: extra['email'],
              isWorker: extra['isWorker'],
            );
          },
        ),
        GoRoute(
          path: '/complete-worker-registration',
          builder: (_, __) => const CompleteWorkerRegistrationScreen(),
        ),
        GoRoute(
          path: '/complete-worker-profile',
          builder: (_, __) => const WorkerCompleteProfileScreen(),
        ),
        GoRoute(
          path: '/worker/verification',
          builder: (_, __) => const WorkerVerificationScreen(),
        ),
        
        // Rutas legacy para compatibilidad
        GoRoute(
          path: '/', 
          redirect: (_, __) => '/login',
        ),
        GoRoute(
          path: '/homeClient',
          redirect: (_, __) => '/client/dashboard',
        ),
        GoRoute(
          path: '/homeWorker',
          redirect: (_, __) => '/worker/dashboard',
        ),
        GoRoute(
          path: '/workerProfile',
          redirect: (_, __) => '/worker/profile',
        ),
        GoRoute(
          path: '/workerHistory',
          redirect: (_, __) => '/worker/history',
        ),
        GoRoute(
          path: '/workerChats',
          redirect: (_, __) => '/worker/chats',
        ),
        GoRoute(
          path: '/worker/availability',
          builder: (_, __) => const WorkerAvailabilityScreen(),
        ),
      ],
      redirect: (context, state) async {
        final auth = context.read<AuthProvider>();
        final nestJS = context.read<NestJSProvider>();
        final isAuth = auth.isAuthenticated || nestJS.isAuthenticated;
        
        // Rutas públicas que no requieren autenticación
        final publicRoutes = [
          '/login',
          '/register',
          '/email-verification',
          '/worker/verification',
        ];
        
        final isPublicRoute = publicRoutes.contains(state.fullPath);

        // Si no está autenticado y no está en una ruta pública, redirigir a login
        if (!isAuth && !isPublicRoute) {
          return '/login';
        }
        
        // Si está autenticado y está en una ruta pública, redirigir según el rol
        if (isAuth && isPublicRoute) {
          final userRole = _getUserRole(auth, nestJS);
          print('🔍 Usuario autenticado - Rol detectado: $userRole');
          print('🔍 NestJS autenticado: ${nestJS.isAuthenticated}');
          print('🔍 Auth autenticado: ${auth.isAuthenticated}');
          if (nestJS.currentUser != null) {
            print('🔍 Usuario NestJS: ${nestJS.currentUser}');
          }
          
          if (userRole == 'worker') {
            print('🔍 Usuario es trabajador, verificando perfil completo...');
            // Verificar si el trabajador tiene perfil completo
            final hasProfile = await nestJS.hasWorkerProfile();
            print('🔍 Tiene perfil completo: $hasProfile');
            if (!hasProfile) {
              print('🔍 Redirigiendo a completar perfil de trabajador');
              return '/complete-worker-profile';
            }
            // Verificar si el trabajador tiene servicios configurados
            final hasServices = await nestJS.hasWorkerServices();
            print('🔍 Tiene servicios: $hasServices');
            if (!hasServices) {
              print('🔍 Redirigiendo a completar registro de trabajador');
              return '/complete-worker-registration';
            }
            print('🔍 Redirigiendo a dashboard de trabajador');
            return '/worker/dashboard';
          } else {
            print('🔍 Redirigiendo a dashboard de cliente');
            return '/client/dashboard';
          }
        }
        
        return null;
      },
    );
  }
  
  // Determinar el rol del usuario
  static String _getUserRole(AuthProvider auth, NestJSProvider nestJS) {
    // Priorizar NestJS si está autenticado
    if (nestJS.isAuthenticated && nestJS.currentUser != null) {
      final role = nestJS.currentUser!['role'];
      if (role != null) {
        // Intentar obtener el nombre del rol primero
        if (role['name'] != null) {
          return role['name'];
        }
        // Si no hay nombre, usar el ID para determinar el rol
        final roleId = role['id'];
        if (roleId == 3) return 'worker';
        if (roleId == 2) return 'user';
        if (roleId == 1) return 'admin';
        if (roleId == 4) return 'super_admin';
      }
      return 'user';
    }
    
    // Fallback a Firebase Auth
    if (auth.isAuthenticated && auth.currentUser != null) {
      return auth.currentUser!.role;
    }
    
    return 'user';
  }
}

// Pantalla de verificación para trabajadores (placeholder)
class WorkerVerificationScreen extends StatelessWidget {
  const WorkerVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Cuenta'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user,
              size: 80,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Cuenta en Verificación',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tu cuenta está siendo revisada por nuestro equipo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Recibirás una notificación cuando tu cuenta sea aprobada.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
