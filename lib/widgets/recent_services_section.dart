import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecentServicesSection extends StatelessWidget {
  const RecentServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos simulados de servicios recientes
    final recentServices = [
      {
        'workerName': 'Luis Rodríguez',
        'service': 'Electricista',
        'date': 'Hoy',
        'status': 'completado',
        'rating': 5.0,
        'amount': 'S/. 120',
        'avatar': 'LR',
      },
      {
        'workerName': 'Ana Torres',
        'service': 'Gasfitero',
        'date': 'Ayer',
        'status': 'completado',
        'rating': 4.5,
        'amount': 'S/. 90',
        'avatar': 'AT',
      },
      {
        'workerName': 'Miguel Santos',
        'service': 'Técnico en computadoras',
        'date': '2 días',
        'status': 'completado',
        'rating': 4.8,
        'amount': 'S/. 80',
        'avatar': 'MS',
      },
    ];

    if (recentServices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Servicios Recientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Aquí podrías navegar a una pantalla de historial completo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ver historial completo'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Text(
                  'Ver todo',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children:
                  recentServices.asMap().entries.map((entry) {
                    final index = entry.key;
                    final service = entry.value;
                    final isLast = index == recentServices.length - 1;

                    return Column(
                      children: [
                        _buildServiceItem(context, service),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: Colors.grey[200],
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, Map<String, dynamic> service) {
    final color = _getServiceColor(service['service']);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                service['avatar'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Información del servicio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service['workerName'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        service['status'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  service['service'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[400], size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${service['rating']}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, color: Colors.grey[500], size: 12),
                    const SizedBox(width: 4),
                    Text(
                      service['date'],
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Text(
                      service['amount'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botón de acción
          PopupMenuButton<String>(
            onSelected:
                (value) => _handleServiceAction(value, service, context),
            icon: Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder:
                (ctx) => [
                  const PopupMenuItem(
                    value: 'ver',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Ver detalles'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'contratar',
                    child: Row(
                      children: [
                        Icon(Icons.handshake_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Contratar de nuevo'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'calificar',
                    child: Row(
                      children: [
                        Icon(Icons.star_outline, size: 16),
                        SizedBox(width: 8),
                        Text('Calificar'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  void _handleServiceAction(
    String action,
    Map<String, dynamic> service,
    BuildContext context,
  ) {
    switch (action) {
      case 'ver':
        _showServiceDetails(service, context);
        break;
      case 'contratar':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contratando de nuevo a ${service['workerName']}'),
            backgroundColor: Colors.green[600],
          ),
        );
        break;
      case 'calificar':
        _showRatingDialog(service, context);
        break;
    }
  }

  void _showServiceDetails(Map<String, dynamic> service, BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getServiceColor(service['service']),
                        _getServiceColor(service['service']).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      service['avatar'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    service['workerName'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Servicio', service['service']),
                _buildDetailRow('Fecha', service['date']),
                _buildDetailRow('Estado', service['status']),
                _buildDetailRow('Calificación', '${service['rating']} ⭐'),
                _buildDetailRow('Monto', service['amount']),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  void _showRatingDialog(Map<String, dynamic> service, BuildContext context) {
    double rating = service['rating'].toDouble();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Calificar Servicio',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¿Cómo calificarías el servicio de ${service['workerName']}?',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () {
                              setState(() {
                                rating = index + 1.0;
                              });
                            },
                            icon: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber[400],
                              size: 32,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${rating.toInt()} estrellas',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Calificación enviada: ${rating.toInt()} estrellas',
                            ),
                            backgroundColor: Colors.green[600],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Enviar'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Color _getServiceColor(String service) {
    switch (service) {
      case 'Electricista':
        return Colors.yellow[600]!;
      case 'Gasfitero':
        return Colors.blue[600]!;
      case 'Carpintero':
        return Colors.brown[600]!;
      case 'Técnico en computadoras':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
