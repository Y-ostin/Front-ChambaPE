class ApiConfig {
  // URL base del backend NestJS
  static const String baseUrl = 'http://192.168.15.80:3000';

  // Endpoints de autenticación
  static const String loginEndpoint = '/auth/email/login';
  static const String registerEndpoint = '/auth/email/register';
  static const String confirmEmailEndpoint = '/auth/email/confirm';
  static const String forgotPasswordEndpoint = '/auth/forgot/password';
  static const String resetPasswordEndpoint = '/auth/reset/password';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String meEndpoint = '/auth/me';

  // Endpoints de usuarios
  static const String usersEndpoint = '/users';

  // Endpoints de trabajadores
  static const String workersEndpoint = '/workers';
  static const String workerRegisterEndpoint = '/workers/register';

  // Endpoints de trabajos
  static const String jobsEndpoint = '/jobs';
  static const String jobCategoriesEndpoint = '/jobs/categories';

  // Endpoints de ofertas
  static const String offersEndpoint = '/offers';

  // Endpoints de servicios
  static const String servicesEndpoint = '/services';
  static const String serviceCategoriesEndpoint = '/service-categories';

  // Endpoints de archivos
  static const String filesEndpoint = '/files';
  static const String uploadEndpoint = '/files/upload';

  // Endpoints de matching
  static const String matchingEndpoint = '/matching';

  // Endpoints de pagos
  static const String paymentsEndpoint = '/payments';

  // Endpoints de calificaciones
  static const String ratingsEndpoint = '/ratings';

  // Endpoints de chat
  static const String chatEndpoint = '/chat';
  static const String messagesEndpoint = '/chat/messages';

  // Endpoints de notificaciones
  static const String notificationsEndpoint = '/notifications';

  // Endpoints de geolocalización
  static const String locationEndpoint = '/location';

  // Configuración de timeout
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Configuración de paginación
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;

  // Configuración de archivos
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];

  // Configuración de validación
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 1000;

  // Configuración de geolocalización
  static const double defaultRadiusKm = 15.0;
  static const double maxRadiusKm = 50.0;
  static const double minRadiusKm = 1.0;

  // Configuración de precios
  static const double minPrice = 0.0;
  static const double maxPrice = 10000.0;

  // Configuración de calificaciones
  static const double minRating = 1.0;
  static const double maxRating = 5.0;

  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'ChambaPE-Flutter/1.0.0',
  };

  // Códigos de estado HTTP
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusConflict = 409;
  static const int statusUnprocessableEntity = 422;
  static const int statusInternalServerError = 500;

  // Mensajes de error comunes
  static const String errorNetwork = 'Error de conexión. Verifica tu internet.';
  static const String errorTimeout = 'Tiempo de espera agotado.';
  static const String errorServer = 'Error del servidor. Intenta más tarde.';
  static const String errorUnauthorized = 'No autorizado. Inicia sesión.';
  static const String errorForbidden = 'Acceso denegado.';
  static const String errorNotFound = 'Recurso no encontrado.';
  static const String errorValidation = 'Datos inválidos.';
  static const String errorUnknown = 'Error desconocido.';

  // Validaciones de campos
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= minPasswordLength &&
        password.length <= maxPasswordLength;
  }

  static bool isValidName(String name) {
    return name.length >= minNameLength &&
        name.length <= maxNameLength &&
        RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(name);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone);
  }

  static bool isValidDNI(String dni) {
    return RegExp(r'^\d{8}$').hasMatch(dni);
  }

  static bool isValidDescription(String description) {
    return description.length >= minDescriptionLength &&
        description.length <= maxDescriptionLength;
  }

  static bool isValidPrice(double price) {
    return price >= minPrice && price <= maxPrice;
  }

  static bool isValidRating(double rating) {
    return rating >= minRating && rating <= maxRating;
  }

  static bool isValidRadius(double radius) {
    return radius >= minRadiusKm && radius <= maxRadiusKm;
  }

  static bool isValidLatitude(double latitude) {
    return latitude >= -90 && latitude <= 90;
  }

  static bool isValidLongitude(double longitude) {
    return longitude >= -180 && longitude <= 180;
  }

  // Validación de archivos
  static bool isValidImageFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedImageTypes.contains(extension);
  }

  static bool isValidDocumentFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedDocumentTypes.contains(extension);
  }

  static bool isValidFileSize(int fileSize) {
    return fileSize <= maxFileSize;
  }

  // Formateo de errores
  static String formatError(dynamic error) {
    if (error is String) {
      return error;
    } else if (error is Map<String, dynamic>) {
      return error['message'] ?? error['error'] ?? errorUnknown;
    } else {
      return error.toString();
    }
  }

  // Construcción de URLs
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  static String buildUrlWithParams(
    String endpoint,
    Map<String, dynamic> params,
  ) {
    final uri = Uri.parse('$baseUrl$endpoint');
    final queryParams = <String, String>{};

    params.forEach((key, value) {
      if (value != null) {
        queryParams[key] = value.toString();
      }
    });

    return uri.replace(queryParameters: queryParams).toString();
  }
}
