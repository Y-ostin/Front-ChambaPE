import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';

class NestJSProvider extends ChangeNotifier {
  final String _baseUrl = ApiConfig.baseUrl;
  String? _authToken;
  Map<String, dynamic>? _currentUser;

  String? get authToken => _authToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null;
  String get baseUrl => _baseUrl;

  // Headers base para las peticiones
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Probar conexión con el servidor
  Future<bool> testConnection() async {
    try {
      debugPrint('Testing connection to: $_baseUrl/health');
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error testing connection: $e');
      return false;
    }
  }

  // Autenticación con NestJS
  Future<Map<String, dynamic>> authenticateWithNestJS(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/email/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        _currentUser = data['user'];
        notifyListeners();
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error de autenticación');
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
      rethrow;
    }
  }

  // Registro de usuario básico
  Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/email/register'),
        headers: _headers,
        body: jsonEncode(userData),
      );

      debugPrint('Registration response status: ${response.statusCode}');
      debugPrint('Registration response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            return data;
          } catch (e) {
            debugPrint('Error parsing JSON response: $e');
            return {'message': 'Registro exitoso'};
          }
        } else {
          return {'message': 'Registro exitoso'};
        }
      } else {
        String errorMessage = 'Error en el registro';
        if (response.body.isNotEmpty) {
          try {
            final error = jsonDecode(response.body);
            errorMessage = error['message'] ?? errorMessage;
          } catch (e) {
            debugPrint('Error parsing error response: $e');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  // Registro de cliente
  Future<Map<String, dynamic>> registerClient(Map<String, dynamic> userData) async {
    try {
      debugPrint('🚀 Iniciando registro de cliente...');
      debugPrint('🚀 URL: $_baseUrl/auth/email/register-client');
      debugPrint('🚀 Headers: $_headers');
      debugPrint('🚀 Data: ${jsonEncode(userData)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/email/register-client'),
        headers: _headers,
        body: jsonEncode(userData),
      );

      debugPrint('Client registration response status: ${response.statusCode}');
      debugPrint('Client registration response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            return data;
          } catch (e) {
            debugPrint('Error parsing JSON response: $e');
            return {'message': 'Cliente registrado exitosamente'};
          }
        } else {
          return {'message': 'Cliente registrado exitosamente'};
        }
      } else {
        String errorMessage = 'Error en el registro de cliente';
        if (response.body.isNotEmpty) {
          try {
            final error = jsonDecode(response.body);
            errorMessage = error['message'] ?? errorMessage;
          } catch (e) {
            debugPrint('Error parsing error response: $e');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Client registration error: $e');
      rethrow;
    }
  }

  // Registro de trabajador (método antiguo - mantener para compatibilidad)
  Future<Map<String, dynamic>> registerWorker(Map<String, dynamic> workerData) async {
    try {
      debugPrint('🔧 Iniciando registro de trabajador...');
      debugPrint('🔧 URL: $_baseUrl/workers/register-public');
      debugPrint('🔧 Headers: $_headers');
      debugPrint('🔧 Data: ${jsonEncode(workerData)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/workers/register-public'),
        headers: _headers,
        body: jsonEncode(workerData),
      );

      debugPrint('Worker registration response status: ${response.statusCode}');
      debugPrint('Worker registration response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            return data;
          } catch (e) {
            debugPrint('Error parsing JSON response: $e');
            return {'message': 'Registro de trabajador exitoso'};
          }
        } else {
          return {'message': 'Registro de trabajador exitoso'};
        }
      } else {
        String errorMessage = 'Error en el registro de trabajador';
        if (response.body.isNotEmpty) {
          try {
            final error = jsonDecode(response.body);
            errorMessage = error['message'] ?? errorMessage;
          } catch (e) {
            debugPrint('Error parsing error response: $e');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Worker registration error: $e');
      rethrow;
    }
  }

  // Registro público de trabajador con archivos
  Future<Map<String, dynamic>> registerWorkerPublic({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dniNumber,
    required File dniFrontal,
    required File dniPosterior,
    required File certificatePdf,
    String? description,
    double? radiusKm,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      debugPrint('🚀 Iniciando registro público de trabajador...');
      
      // Crear request multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/workers/register-public'),
      );

      // Agregar campos de texto
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['firstName'] = firstName;
      request.fields['lastName'] = lastName;
      request.fields['dniNumber'] = dniNumber;
      if (description != null) request.fields['description'] = description;
      if (radiusKm != null) request.fields['radiusKm'] = radiusKm.toString();
      if (address != null) request.fields['address'] = address;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();

      // Verificar existencia y tamaño de los archivos antes de agregarlos
      print('DNI Frontal: \\${dniFrontal.path} - \\${await dniFrontal.length()} bytes');
      print('DNI Posterior: \\${dniPosterior.path} - \\${await dniPosterior.length()} bytes');
      print('Certificado: \\${certificatePdf.path} - \\${await certificatePdf.length()} bytes');

      // Agregar archivos usando MultipartFile.fromPath
      request.files.add(await http.MultipartFile.fromPath('dniFrontal', dniFrontal.path));
      request.files.add(await http.MultipartFile.fromPath('dniPosterior', dniPosterior.path));
      request.files.add(await http.MultipartFile.fromPath('certUnico', certificatePdf.path));

      // Agregar el mapeo flexible para el backend
      final filesMeta = [
        {"field": "dniFrontal", "type": "dni_frontal"},
        {"field": "dniPosterior", "type": "dni_posterior"},
        {"field": "certUnico", "type": "dni_pdf"},
      ];
      request.fields['filesMeta'] = jsonEncode(filesMeta);

      debugPrint('📤 Enviando registro público de trabajador...');
      debugPrint('📤 Email: $email');
      debugPrint('📤 DNI: $dniNumber');
      debugPrint('📤 Archivos: DNI frontal, DNI posterior, Certificado PDF');

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      debugPrint('📡 Register Public Response Status: ${response.statusCode}');
      debugPrint('📡 Register Public Response Body: $responseData');

      if (response.statusCode == 201) {
        final data = jsonDecode(responseData);
        debugPrint('✅ Registro público de trabajador exitoso');
        return data;
      } else {
        String errorMessage = 'Error en el registro público de trabajador';
        if (responseData.isNotEmpty) {
          try {
            final error = jsonDecode(responseData);
            errorMessage = error['message'] ?? error['errors']?.toString() ?? errorMessage;
          } catch (e) {
            debugPrint('Error parsing error response: $e');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Public worker registration error: $e');
      rethrow;
    }
  }

  // Subir archivo (con autenticación)
  Future<String> uploadFile(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/files/upload'),
      );

      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
        print('🔐 Token de autorización agregado para subida de archivo');
        print('🔐 Token (primeros 20 caracteres): ${_authToken!.substring(0, 20)}...');
      } else {
        print('⚠️ No hay token de autorización disponible para subida de archivo');
      }

      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      print('📤 Enviando archivo: ${file.path}');
      print('📤 Tamaño del archivo: ${await file.length()} bytes');
      print('📤 Nombre del archivo: ${file.path.split('/').last}');
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('📡 Upload Response Status: ${response.statusCode}');
      print('📡 Upload Response Body: $responseData');

      if (response.statusCode == 201) {
        final data = jsonDecode(responseData);
        final url = data['url'] ?? data['path'] ?? '';
        print('✅ Archivo subido exitosamente: $url');
        return url;
      } else {
        print('❌ Error en subida de archivo: ${response.statusCode}');
        try {
          final error = jsonDecode(responseData);
          throw Exception(error['message'] ?? 'Error al subir archivo');
        } catch (e) {
          throw Exception('Error al subir archivo (Status: ${response.statusCode})');
        }
      }
    } catch (e) {
      debugPrint('File upload error: $e');
      rethrow;
    }
  }

  // Subir archivo para registro (sin autenticación)
  Future<String> uploadFileForRegistration(File file, String fieldName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/files/upload-registration'),
      );

      print('📤 Subiendo archivo para registro: ${file.path}');
      print('📤 Campo: $fieldName');
      print('📤 Tamaño del archivo: ${await file.length()} bytes');

      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        fieldName, // Usar el nombre del campo específico
        stream,
        length,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('📡 Upload Registration Response Status: ${response.statusCode}');
      print('📡 Upload Registration Response Body: $responseData');

      if (response.statusCode == 201) {
        final data = jsonDecode(responseData);
        final files = data['files'] as List;
        // Buscar el archivo correspondiente al fieldName
        for (var fileData in files) {
          if (fileData['path'] != null) {
            print('✅ Archivo subido exitosamente para registro: ${fileData['path']}');
            return fileData['path'];
          }
        }
        throw Exception('No se encontró la URL del archivo subido');
      } else {
        print('❌ Error en subida de archivo para registro: ${response.statusCode}');
        try {
          final error = jsonDecode(responseData);
          throw Exception(error['message'] ?? 'Error al subir archivo para registro');
        } catch (e) {
          throw Exception('Error al subir archivo para registro (Status: ${response.statusCode})');
        }
      }
    } catch (e) {
      debugPrint('File upload for registration error: $e');
      rethrow;
    }
  }

  // Obtener datos del usuario actual
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = data;
        notifyListeners();
        return data;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  // Obtener datos de trabajador
  Future<Map<String, dynamic>?> getWorkerData(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/workers/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Get worker data error: $e');
      return null;
    }
  }

  // Verificar si el usuario tiene perfil de trabajador
  Future<bool> hasWorkerProfile() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;
      
      final response = await http.get(
        Uri.parse('$_baseUrl/workers/profile'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Has worker profile error: $e');
      return false;
    }
  }

  // Verificar si el trabajador tiene servicios configurados
  Future<bool> hasWorkerServices() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/workers/services'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final services = data['data'] ?? [];
        return services.isNotEmpty;
      }
      return false;
    } catch (e) {
      debugPrint('Has worker services error: $e');
      return false;
    }
  }

  // Obtener categorías de servicios
  Future<List<Map<String, dynamic>>> getServiceCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/services/categories'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Get service categories error: $e');
      return [];
    }
  }

  // Agregar servicios al trabajador
  Future<bool> addWorkerServices(List<int> serviceIds) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/workers/services'),
        headers: _headers,
        body: jsonEncode({'serviceIds': serviceIds}),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Add worker services error: $e');
      return false;
    }
  }

  // Confirmar email con método GET
  Future<bool> confirmEmailGet(String hash) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/confirm-email?hash=$hash'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Confirm email GET error: $e');
      return false;
    }
  }

  // Toggle disponibilidad del trabajador
  Future<bool> toggleActiveToday() async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/workers/toggle-availability'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Toggle active today error: $e');
      return false;
    }
  }

  // Actualizar ubicación del trabajador
  Future<bool> updateWorkerLocation(double latitude, double longitude) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/workers/me/location'),
        headers: _headers,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      debugPrint('📡 Update Location Response Status: ${response.statusCode}');
      debugPrint('📡 Update Location Response Body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update worker location error: $e');
      return false;
    }
  }

  // Actualizar disponibilidad del trabajador
  Future<bool> updateWorkerAvailability(String userId, bool isAvailable) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/workers/$userId'),
        headers: _headers,
        body: jsonEncode({
          'isAvailable': isAvailable,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update availability error: $e');
      return false;
    }
  }

  // Obtener trabajos del trabajador
  Future<List<Map<String, dynamic>>> getWorkerJobs(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/workers/$userId/jobs'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Get worker jobs error: $e');
      return [];
    }
  }

  // Obtener trabajos disponibles para clientes
  Future<List<Map<String, dynamic>>> getAvailableJobs({
    double? latitude,
    double? longitude,
    int? categoryId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      if (categoryId != null) queryParams['categoryId'] = categoryId.toString();

      final uri = Uri.parse('$_baseUrl/jobs').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Get available jobs error: $e');
      return [];
    }
  }

  // Verificar conexión con el servidor
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection check error: $e');
      return false;
    }
  }

  // Verificar si el usuario está verificado
  Future<bool> isUserVerified(String email) async {
    try {
      final loginResponse = await http.post(
        Uri.parse('$_baseUrl/auth/email/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': '',
        }),
      );

      if (loginResponse.statusCode == 200) {
        final data = jsonDecode(loginResponse.body);
        return data['user']?['status']?['name'] == 'active';
      }
      return false;
    } catch (e) {
      debugPrint('Check user verification error: $e');
      return false;
    }
  }

  // Recuperar contraseña
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot/password'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Forgot password error: $e');
      return false;
    }
  }

  // Resetear contraseña
  Future<bool> resetPassword(String hash, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset/password'),
        headers: _headers,
        body: jsonEncode({
          'hash': hash,
          'password': password,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Reset password error: $e');
      return false;
    }
  }

  // Obtener servicios del trabajador
  Future<List<Map<String, dynamic>>> getWorkerServices() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/workers/services'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Get worker services error: $e');
      return [];
    }
  }

  // Cerrar sesión
  void logout() {
    _authToken = null;
    _currentUser = null;
    notifyListeners();
  }

  // Cambiar disponibilidad del trabajador (toggle)
  Future<bool> toggleWorkerAvailability() async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/workers/me/toggle-active'),
        headers: _headers,
      );
      debugPrint('📡 Toggle Availability Response Status: ${response.statusCode}');
      debugPrint('📡 Toggle Availability Response Body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Toggle worker availability error: $e');
      return false;
    }
  }
} 