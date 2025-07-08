import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ValidateService {
  static const String baseUrl = 'http://192.168.0.64:3000';

  // Validar DNI y obtener nombres/apellidos
  static Future<Map<String, dynamic>?> getDniData(String dni) async {
    try {
      print('🔍 Consultando DNI: $dni');
      final response = await http.get(
        Uri.parse('$baseUrl/validate/dni?dni=$dni'),
        headers: {
          'Authorization':
              'Bearer 4eea59a3b8cf6b36a7c01557fda685dd30049354367d0f03b9d0c00e3fc17015',
          'Accept': 'application/json',
        },
      );

      print('📡 DNI Response Status: ${response.statusCode}');
      print('📡 DNI Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Error en consulta DNI: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Excepción en consulta DNI: $e');
      return null;
    }
  }

  // Validar Certificado Único Laboral y DNIs
  static Future<Map<String, dynamic>?> validateCertUnico({
    required String dni,
    required File dniFrontal,
    required File dniPosterior,
    required File certUnico,
  }) async {
    try {
      print('🔍 Iniciando validación de certificado único');
      print('📁 DNI Frontal: ${dniFrontal.path}');
      print('📁 DNI Posterior: ${dniPosterior.path}');
      print('📁 Certificado: ${certUnico.path}');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/validate/cert-unico'),
      );

      // Agregar el DNI en el body
      request.fields['dni'] = dni;

      request.files.add(
        await http.MultipartFile.fromPath('dniFrontal', dniFrontal.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('dniPosterior', dniPosterior.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('certUnico', certUnico.path),
      );

      print('📤 Enviando archivos al backend...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Cert-Unico Response Status: ${response.statusCode}');
      print('📡 Cert-Unico Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          print('✅ Validación exitosa: $data');
          print('🔍 Tipo de valido en servicio: ${data['valido'].runtimeType}');
          print('🔍 Valor de valido en servicio: ${data['valido']}');
          print('✅ Retornando datos de validación exitosa');
          return data;
        } catch (e) {
          print('❌ Error parseando JSON: $e');
          return {
            'valido': false,
            'mensaje': 'Error al procesar respuesta del servidor',
            'antecedentes': [],
          };
        }
      } else {
        print('❌ Error en validación: ${response.statusCode}');
        print('❌ Respuesta del servidor: ${response.body}');
        // Intentar decodificar el error y retornarlo
        try {
          final errorData = jsonDecode(response.body);
          return {
            'valido': false,
            'mensaje':
                errorData['message'] ??
                'Error en la validación (Status: ${response.statusCode})',
            'antecedentes': errorData['antecedentes'] ?? [],
          };
        } catch (e) {
          return {
            'valido': false,
            'mensaje':
                'Error interno del servidor (Status: ${response.statusCode})',
            'antecedentes': [],
          };
        }
      }
    } catch (e) {
      print('❌ Excepción en validación: $e');
      return {
        'valido': false,
        'mensaje': 'Error de conexión: $e',
        'antecedentes': [],
      };
    }
  }
}
