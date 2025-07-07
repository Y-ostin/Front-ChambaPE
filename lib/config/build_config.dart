class BuildConfig {
  // Configuración para diferentes entornos de build
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // URLs de la API según el entorno
  static const Map<String, String> _apiUrls = {
    'development': 'http://10.0.2.2:3000/api',
    'staging': 'https://staging-api.chambape.com/api',
    'production': 'https://api.chambape.com/api',
  };

  // URLs de Firebase según el entorno
  static const Map<String, String> _firebaseUrls = {
    'development': 'https://chambape-dev.firebaseapp.com',
    'staging': 'https://chambape-staging.firebaseapp.com',
    'production': 'https://chambape-prod.firebaseapp.com',
  };

  // Obtener URL de la API según el entorno
  static String get apiUrl => _apiUrls[_environment] ?? _apiUrls['development']!;

  // Obtener URL de Firebase según el entorno
  static String get firebaseUrl => _firebaseUrls[_environment] ?? _firebaseUrls['development']!;

  // Verificar si estamos en desarrollo
  static bool get isDevelopment => _environment == 'development';

  // Verificar si estamos en staging
  static bool get isStaging => _environment == 'staging';

  // Verificar si estamos en producción
  static bool get isProduction => _environment == 'production';

  // Configuración de logging
  static bool get enableLogging => !isProduction;

  // Configuración de analytics
  static bool get enableAnalytics => isProduction;

  // Configuración de crash reporting
  static bool get enableCrashReporting => isProduction;

  // Timeout de conexión según el entorno
  static int get connectionTimeoutSeconds {
    switch (_environment) {
      case 'production':
        return 30;
      case 'staging':
        return 45;
      default:
        return 60;
    }
  }

  // Número máximo de reintentos según el entorno
  static int get maxRetries {
    switch (_environment) {
      case 'production':
        return 2;
      case 'staging':
        return 3;
      default:
        return 5;
    }
  }

  // Configuración de cache
  static Duration get cacheDuration {
    switch (_environment) {
      case 'production':
        return const Duration(hours: 1);
      case 'staging':
        return const Duration(minutes: 30);
      default:
        return const Duration(minutes: 5);
    }
  }

  // Configuración de rate limiting
  static int get maxRequestsPerMinute {
    switch (_environment) {
      case 'production':
        return 100;
      case 'staging':
        return 200;
      default:
        return 1000;
    }
  }

  // Configuración de compresión
  static bool get enableCompression => isProduction;

  // Configuración de SSL pinning (solo en producción)
  static bool get enableSSLPinning => isProduction;

  // Configuración de debug
  static bool get enableDebug {
    switch (_environment) {
      case 'production':
        return false;
      case 'staging':
        return true;
      default:
        return true;
    }
  }

  // Configuración de hot reload
  static bool get enableHotReload => isDevelopment;

  // Configuración de performance monitoring
  static bool get enablePerformanceMonitoring => isProduction;

  // Configuración de error reporting
  static bool get enableErrorReporting => isProduction || isStaging;

  // Configuración de feature flags
  static Map<String, bool> get featureFlags {
    switch (_environment) {
      case 'production':
        return {
          'chat_enabled': true,
          'payment_enabled': true,
          'notifications_enabled': true,
          'analytics_enabled': true,
          'debug_mode': false,
        };
      case 'staging':
        return {
          'chat_enabled': true,
          'payment_enabled': false,
          'notifications_enabled': true,
          'analytics_enabled': true,
          'debug_mode': true,
        };
      default:
        return {
          'chat_enabled': true,
          'payment_enabled': false,
          'notifications_enabled': false,
          'analytics_enabled': false,
          'debug_mode': true,
        };
    }
  }

  // Obtener información del build
  static Map<String, dynamic> get buildInfo {
    return {
      'environment': _environment,
      'apiUrl': apiUrl,
      'firebaseUrl': firebaseUrl,
      'isDevelopment': isDevelopment,
      'isStaging': isStaging,
      'isProduction': isProduction,
      'enableLogging': enableLogging,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'connectionTimeout': connectionTimeoutSeconds,
      'maxRetries': maxRetries,
      'cacheDuration': cacheDuration.inSeconds,
      'maxRequestsPerMinute': maxRequestsPerMinute,
      'enableCompression': enableCompression,
      'enableSSLPinning': enableSSLPinning,
      'enableDebug': enableDebug,
      'enableHotReload': enableHotReload,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'enableErrorReporting': enableErrorReporting,
      'featureFlags': featureFlags,
    };
  }
} 