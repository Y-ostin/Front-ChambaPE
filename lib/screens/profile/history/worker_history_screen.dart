import 'package:flutter/material.dart';

class WorkerHistoryScreen extends StatelessWidget {
  const WorkerHistoryScreen({super.key});

  final List<Map<String, dynamic>> mockHistory = const [
    {
      'cliente': 'María López',
      'servicio': 'Electricidad',
      'fecha': '10/06/2025',
      'calificacion': 5.0,
      'comentario': 'Excelente servicio, muy puntual.'
    },
    {
      'cliente': 'Pedro Ruiz',
      'servicio': 'Gasfitería',
      'fecha': '07/06/2025',
      'calificacion': 4.5,
      'comentario': 'Buen trabajo aunque tardó un poco.'
    },
    {
      'cliente': 'Sofía García',
      'servicio': 'Instalación de luces LED',
      'fecha': '03/06/2025',
      'calificacion': 4.0,
      'comentario': 'Recomendado, pero podría mejorar en limpieza.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de trabajos'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockHistory.length,
        itemBuilder: (context, index) {
          final trabajo = mockHistory[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('${trabajo['servicio']} con ${trabajo['cliente']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fecha: ${trabajo['fecha']}'),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text('${trabajo['calificacion']}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${trabajo['comentario']}"',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
