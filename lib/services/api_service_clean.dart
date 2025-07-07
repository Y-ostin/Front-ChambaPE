import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';
  static String? _authToken;
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Verificar conexión con el backend
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking connection: $e');
      return false;
    }
  }

  // Registro de usuario
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/email/register'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        }),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Login de usuario
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/email/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      final result = _handleResponse(response);
      
      if (result['success'] && result['data']?['token'] != null) {
        _authToken = result['data']['token'];
        await _saveToken(_authToken!);
      }
      
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Obtener perfil del usuario autenticado
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      await _loadToken();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener perfil: $e',
      };
    }
  }

  // Registrar como trabajador
  static Future<Map<String, dynamic>> registerWorker({
    required String phoneNumber,
    required double latitude,
    required double longitude,
    required String address,
    String? specialty,
    String? bio,
    List<int>? serviceIds,
  }) async {
    try {
      await _loadToken();
      final response = await http.post(
        Uri.parse('$baseUrl/workers/register'),
        headers: _headers,
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'specialty': specialty,
          'bio': bio,
          'isActive': true,
          'available': true,
          if (serviceIds != null) 'serviceIds': serviceIds,
        }),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al registrar trabajador: $e',
      };
    }
  }

  // Obtener trabajadores cercanos
  static Future<List<Map<String, dynamic>>> getNearbyWorkers({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      await _loadToken();
      final response = await http.get(
        Uri.parse('$baseUrl/workers/nearby?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getting nearby workers: $e');
      return [];
    }
  }

  // Obtener categorías de servicios
  static Future<List<Map<String, dynamic>>> getServiceCategories() async {
    try {
      await _loadToken();
      final response = await http.get(
        Uri.parse('$baseUrl/service-categories'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getting service categories: $e');
      return [];
    }
  }

  // Crear trabajo
  static Future<Map<String, dynamic>> createJob({
    required String title,
    required String description,
    required int serviceCategoryId,
    required double latitude,
    required double longitude,
    required String address,
    double? estimatedBudget,
  }) async {
    try {
      await _loadToken();
      final response = await http.post(
        Uri.parse('$baseUrl/jobs'),
        headers: _headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'serviceCategoryId': serviceCategoryId,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'estimatedBudget': estimatedBudget,
        }),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al crear trabajo: $e',
      };
    }
  }

  // Obtener mis trabajos
  static Future<List<Map<String, dynamic>>> getMyJobs() async {
    try {
      await _loadToken();
      final response = await http.get(
        Uri.parse('$baseUrl/jobs/my-jobs'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getting my jobs: $e');
      return [];
    }
  }

  // Obtener ofertas del trabajador
  static Future<List<Map<String, dynamic>>> getMyOffers() async {
    try {
      await _loadToken();
      final response = await http.get(
        Uri.parse('$baseUrl/offers/my-offers'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getting my offers: $e');
      return [];
    }
  }

  // Crear oferta para un trabajo
  static Future<Map<String, dynamic>> createOffer({
    required int jobId,
    required double proposedPrice,
    String? message,
  }) async {
    try {
      await _loadToken();
      final response = await http.post(
        Uri.parse('$baseUrl/offers'),
        headers: _headers,
        body: jsonEncode({
          'jobId': jobId,
          'proposedPrice': proposedPrice,
          'message': message,
        }),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al crear oferta: $e',
      };
    }
  }

  // Métodos genéricos para compatibilidad con NestJSProvider
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      await _loadToken();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Error en GET request: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      await _loadToken();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Error en POST request: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      await _loadToken();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Error en PUT request: $e',
      };
    }
  }

  static void setAuthToken(String token) {
    _authToken = token;
    _saveToken(token);
  }

  static void dispose() {
    // Método para limpiar recursos si es necesario
    _authToken = null;
  }

  // Logout
  static Future<void> logout() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Métodos privados
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': body,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Error en la solicitud',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al procesar respuesta: $e',
        'statusCode': response.statusCode,
      };
    }
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> _loadToken() async {
    if (_authToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
    }
  }

  // Obtener token actual
  static Future<String?> getToken() async {
    await _loadToken();
    return _authToken;
  }

  // Verificar si hay token guardado
  static Future<bool> hasToken() async {
    await _loadToken();
    return _authToken != null;
  }
}
