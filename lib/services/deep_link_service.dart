import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import '../providers/nestjs_provider.dart';
import '../providers/auth_provider.dart';

class DeepLinkService {
  static StreamSubscription? _subscription;
  static bool _isInitialized = false;
  static final AppLinks _appLinks = AppLinks();

  static void initialize(BuildContext context) {
    if (_isInitialized) return;
    
    _isInitialized = true;
    
    // Manejar links iniciales
    _appLinks.getInitialAppLink().then((Uri? uri) {
      if (uri != null) {
        _handleLink(uri.toString(), context);
      }
    });

    // Manejar links cuando la app está abierta
    _subscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleLink(uri.toString(), context);
      }
    }, onError: (err) {
      print('Error en deep link: $err');
    });
  }

  static void _handleLink(String link, BuildContext context) {
    print('🔗 Deep link recibido: $link');
    
    try {
      final uri = Uri.parse(link);
      
      if (uri.scheme == 'chambape' && uri.host == 'email-verification') {
        final hash = uri.queryParameters['hash'];
        if (hash != null) {
          _handleEmailVerification(hash, context);
        }
      }
    } catch (e) {
      print('❌ Error procesando deep link: $e');
    }
  }

    static Future<void> _handleEmailVerification(String hash, BuildContext context) async {
    try {
      print('🔐 Procesando verificación de email con hash: $hash');
      
      final nestJSProvider = context.read<NestJSProvider>();
      
      // Confirmar email usando el endpoint GET que funciona
      final success = await nestJSProvider.confirmEmailGet(hash);
      
      if (success) {
        print('✅ Email verificado exitosamente');
        
        // Después de verificar el email, redirigir al login
        // El usuario podrá completar su perfil de trabajador después del login
        if (context.mounted) {
          try {
            // Usar GoRouter de forma segura
            if (GoRouter.of(context) != null) {
              GoRouter.of(context).go('/login');
            } else {
              // Fallback: usar Navigator si GoRouter no está disponible
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          } catch (e) {
            print('⚠️ Error al redirigir después de verificación: $e');
          }
        }
      } else {
        print('❌ Error al verificar email');
      }
    } catch (e) {
      print('❌ Error en verificación de email: $e');
    }
  }

  static void dispose() {
    _subscription?.cancel();
    _isInitialized = false;
  }
} 