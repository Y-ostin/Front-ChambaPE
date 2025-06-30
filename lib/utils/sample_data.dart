import 'package:cloud_firestore/cloud_firestore.dart';

class SampleData {
  static final List<Map<String, dynamic>> workers = [
    {
      'uid': 'mMTEUEm5UsOv5q6Zn1CuJNNdGns1', // UID real de Firebase Auth
      'name': 'PEDRO SUAREZ VERTIZ',
      'email': 'pedritols@gmail.com',
      'phone': '988335094',
      'address': 'Av. Ejemplo 123, Arequipa',
      'specialty': 'Carpintero',
      'experience': '4',
      'rating': 4.8,
      'jobsDone': 156,
      'reviewsCount': 89,
      'isAvailable': true,
      'certifications': [
        'Certificación en Carpintería Fina',
        'Restauración de Muebles',
        'Instalación de Gabinetes',
        'Trabajos en Madera',
      ],
    },
    {
      'uid': 'luis_rodriguez_uid',
      'name': 'Luis Rodríguez',
      'email': 'luis.rod@example.com',
      'phone': '+51 987 654 321',
      'address': 'Calle Falsa 456, Arequipa',
      'specialty': 'Gasfitero',
      'experience': '5 años',
      'rating': 4.7,
      'jobsDone': 127,
      'reviewsCount': 67,
      'isAvailable': true,
      'certifications': [
        'Certificación en Instalaciones Sanitarias',
        'Mantenimiento de Sistemas de Agua',
        'Reparación de Tuberías',
      ],
    },
    {
      'uid': 'maria_lopez_uid',
      'name': 'María López',
      'email': 'maria.lopez@example.com',
      'phone': '+51 987 789 012',
      'address': 'Jr. Los Pinos 789, Arequipa',
      'specialty': 'Electricista',
      'experience': '6 años',
      'rating': 4.9,
      'jobsDone': 203,
      'reviewsCount': 145,
      'isAvailable': true,
      'certifications': [
        'Instalaciones Eléctricas',
        'Mantenimiento de Sistemas Eléctricos',
        'Automatización Residencial',
      ],
    },
  ];

  static final List<Map<String, dynamic>> jobs = [
    {
      'workerId': 'mMTEUEm5UsOv5q6Zn1CuJNNdGns1',
      'clientName': 'Ana García',
      'serviceType': 'Instalación de gabinetes',
      'status': 'completed',
      'completedAt': Timestamp.now(),
      'rating': 5.0,
      'clientId': 'ana_garcia_uid',
    },
    {
      'workerId': 'mMTEUEm5UsOv5q6Zn1CuJNNdGns1',
      'clientName': 'Carlos Mendoza',
      'serviceType': 'Reparación de muebles',
      'status': 'completed',
      'completedAt': Timestamp.now(),
      'rating': 4.8,
      'clientId': 'carlos_mendoza_uid',
    },
    {
      'workerId': 'mMTEUEm5UsOv5q6Zn1CuJNNdGns1',
      'clientName': 'María López',
      'serviceType': 'Carpintería',
      'status': 'completed',
      'completedAt': Timestamp.now(),
      'rating': 5.0,
      'clientId': 'maria_lopez_client_uid',
    },
    {
      'workerId': 'mMTEUEm5UsOv5q6Zn1CuJNNdGns1',
      'clientName': 'Pedro Ruiz',
      'serviceType': 'Restauración de mesa',
      'status': 'completed',
      'completedAt': Timestamp.now(),
      'rating': 4.5,
      'clientId': 'pedro_ruiz_uid',
    },
    {
      'workerId': 'luis_rodriguez_uid',
      'clientName': 'Sofía García',
      'serviceType': 'Reparación de tuberías',
      'status': 'completed',
      'completedAt': Timestamp.now(),
      'rating': 4.6,
      'clientId': 'sofia_garcia_uid',
    },
  ];

  static final List<Map<String, dynamic>> reviews = [
    {
      'workerId': 'mMTEUEm5UsOv5q6Zn1CuJNNdGns1',
      'clientName': 'Ana García',
      'comment':
          'Excelente carpintero, muy puntual y amable. Trabajo impecable en los gabinetes.',
      'rating': 5.0,
      'createdAt': Timestamp.now(),
      'clientId': 'ana_garcia_uid',
    },
    {
      'workerId': 'mMTEUEm5UsOv5q6Zn1CuJNNdGns1',
      'clientName': 'Carlos Mendoza',
      'comment':
          'Trabajo impecable y rápido. Lo recomiendo ampliamente para trabajos de carpintería.',
      'rating': 4.8,
      'createdAt': Timestamp.now(),
      'clientId': 'carlos_mendoza_uid',
    },
    {
      'workerId': 'mMTEUEm5UsOv5q6Zn1CuJNNdGns1',
      'clientName': 'María López',
      'comment':
          'Muy profesional y eficiente. Solucionó el problema rápidamente.',
      'rating': 5.0,
      'createdAt': Timestamp.now(),
      'clientId': 'maria_lopez_client_uid',
    },
    {
      'workerId': 'luis_rodriguez_uid',
      'clientName': 'Sofía García',
      'comment': 'Buen trabajo aunque tardó un poco más de lo esperado.',
      'rating': 4.6,
      'createdAt': Timestamp.now(),
      'clientId': 'sofia_garcia_uid',
    },
  ];

  // Función para poblar Firestore con datos de ejemplo
  static Future<void> populateSampleData() async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Agregar trabajadores
      for (final worker in workers) {
        await firestore.collection('workers').doc(worker['uid']).set(worker);
      }

      // Agregar trabajos
      for (final job in jobs) {
        await firestore.collection('jobs').add(job);
      }

      // Agregar reseñas
      for (final review in reviews) {
        await firestore.collection('reviews').add(review);
      }

      print('Datos de ejemplo agregados exitosamente');
    } catch (e) {
      print('Error al agregar datos de ejemplo: $e');
      rethrow; // Re-lanzar el error para que se maneje en la UI
    }
  }
}
