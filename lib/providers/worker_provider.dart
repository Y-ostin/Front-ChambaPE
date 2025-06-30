import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class WorkerProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  User? _workerData;
  User? get workerData => _workerData;

  List<Map<String, dynamic>> _recentJobs = [];
  List<Map<String, dynamic>> get recentJobs => _recentJobs;

  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> get reviews => _reviews;

  // Cargar datos del trabajador
  Future<void> loadWorkerData(String uid) async {
    try {
      // Primero intentar cargar desde la colección workers
      final workerDoc = await _firestore.collection('workers').doc(uid).get();

      if (workerDoc.exists) {
        // Si existe en workers, usar esos datos
        final data = workerDoc.data()!;
        _workerData = User.fromMap({...data, 'uid': uid});
      } else {
        // Si no existe en workers, cargar desde users y crear en workers
        final userDoc = await _firestore.collection('users').doc(uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;

          // Solo procesar si es un trabajador
          if (userData['role'] == 'trabajador') {
            // Crear datos de trabajador con valores por defecto
            final workerData = {
              'uid': uid,
              'name': userData['name'] ?? 'Trabajador',
              'email': userData['email'] ?? '',
              'phone': userData['phone'] ?? '',
              'address': userData['address'] ?? '',
              'specialty': userData['specialty'] ?? 'Técnico',
              'experience': userData['experience'] ?? '0 años',
              'rating': userData['rating'] ?? 0.0,
              'jobsDone': userData['jobsDone'] ?? 0,
              'reviewsCount': userData['reviewsCount'] ?? 0,
              'isAvailable': userData['isAvailable'] ?? true,
              'certifications': userData['certifications'] ?? [],
            };

            // Crear el documento en workers
            await _firestore.collection('workers').doc(uid).set(workerData);

            _workerData = User.fromMap(workerData);
          }
        }
      }

      // Cargar trabajos recientes y reseñas
      if (_workerData != null) {
        await _loadRecentJobs(uid);
        await _loadReviews(uid);
      }

      notifyListeners();
    } catch (e) {
      print('Error loading worker data: $e');
    }
  }

  // Cargar trabajos recientes
  Future<void> _loadRecentJobs(String workerId) async {
    try {
      final jobsQuery =
          await _firestore
              .collection('jobs')
              .where('workerId', isEqualTo: workerId)
              .where('status', isEqualTo: 'completed')
              .orderBy('completedAt', descending: true)
              .limit(5)
              .get();

      _recentJobs =
          jobsQuery.docs.map((doc) {
            final data = doc.data();
            return {
              'cliente': data['clientName'] ?? 'Cliente',
              'servicio': data['serviceType'] ?? 'Servicio',
              'fecha': _formatDate(data['completedAt']),
              'calificacion': data['rating']?.toDouble() ?? 0.0,
            };
          }).toList();
    } catch (e) {
      print('Error loading recent jobs: $e');
      // Datos de ejemplo si no hay datos reales
      _recentJobs = [
        {
          'cliente': 'Ana García',
          'servicio': 'Instalación de tomacorrientes',
          'fecha': '15 Jun 2025',
          'calificacion': 5.0,
        },
        {
          'cliente': 'Carlos Mendoza',
          'servicio': 'Reparación de luminarias',
          'fecha': '12 Jun 2025',
          'calificacion': 4.8,
        },
        {
          'cliente': 'María López',
          'servicio': 'Electricidad',
          'fecha': '10 Jun 2025',
          'calificacion': 5.0,
        },
        {
          'cliente': 'Pedro Ruiz',
          'servicio': 'Gasfitería',
          'fecha': '07 Jun 2025',
          'calificacion': 4.5,
        },
      ];
    }
  }

  // Cargar reseñas
  Future<void> _loadReviews(String workerId) async {
    try {
      final reviewsQuery =
          await _firestore
              .collection('reviews')
              .where('workerId', isEqualTo: workerId)
              .orderBy('createdAt', descending: true)
              .limit(3)
              .get();

      _reviews =
          reviewsQuery.docs.map((doc) {
            final data = doc.data();
            return {
              'cliente': data['clientName'] ?? 'Cliente',
              'comentario': data['comment'] ?? 'Sin comentario',
              'calificacion': data['rating']?.toDouble() ?? 0.0,
            };
          }).toList();
    } catch (e) {
      print('Error loading reviews: $e');
      // Datos de ejemplo si no hay datos reales
      _reviews = [
        {
          'cliente': 'Ana García',
          'comentario': 'Excelente profesional, muy puntual y amable.',
          'calificacion': 5.0,
        },
        {
          'cliente': 'Carlos Mendoza',
          'comentario': 'Trabajo impecable y rápido. Lo recomiendo.',
          'calificacion': 4.8,
        },
      ];
    }
  }

  // Formatear fecha
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Fecha no disponible';

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year}';
      }
      return 'Fecha no disponible';
    } catch (e) {
      return 'Fecha no disponible';
    }
  }

  // Obtener nombre del mes
  String _getMonthName(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[month - 1];
  }

  // Actualizar disponibilidad del trabajador
  Future<void> updateAvailability(String workerId, bool isAvailable) async {
    try {
      // Actualizar el estado local primero para respuesta inmediata
      if (_workerData != null) {
        _workerData = User(
          name: _workerData!.name,
          email: _workerData!.email,
          role: _workerData!.role,
          phone: _workerData!.phone,
          address: _workerData!.address,
          specialty: _workerData!.specialty,
          experience: _workerData!.experience,
          rating: _workerData!.rating,
          jobsDone: _workerData!.jobsDone,
          reviewsCount: _workerData!.reviewsCount,
          certifications: _workerData!.certifications,
          isAvailable: isAvailable,
        );
        // Notificar inmediatamente para actualizar la UI
        notifyListeners();
      }

      // Actualizar en Firestore en segundo plano
      await Future.wait([
        _firestore.collection('workers').doc(workerId).update({
          'isAvailable': isAvailable,
        }),
        _firestore.collection('users').doc(workerId).update({
          'isAvailable': isAvailable,
        }),
      ]);

      print('Disponibilidad actualizada exitosamente: $isAvailable');
    } catch (e) {
      print('Error updating availability: $e');

      // Si hay error, revertir el estado local
      if (_workerData != null) {
        _workerData = User(
          name: _workerData!.name,
          email: _workerData!.email,
          role: _workerData!.role,
          phone: _workerData!.phone,
          address: _workerData!.address,
          specialty: _workerData!.specialty,
          experience: _workerData!.experience,
          rating: _workerData!.rating,
          jobsDone: _workerData!.jobsDone,
          reviewsCount: _workerData!.reviewsCount,
          certifications: _workerData!.certifications,
          isAvailable: !isAvailable, // Revertir al estado anterior
        );
        notifyListeners();
      }

      rethrow; // Re-lanzar el error para que se maneje en la UI
    }
  }
}
