import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListWorkerScreen extends StatelessWidget {
  const ChatListWorkerScreen({super.key});

  final List<Map<String, dynamic>> mockChats = const [
    {
      'nombre': 'María López',
      'servicio': 'Electricidad',
      'ultimoMensaje': 'Gracias, quedó excelente el trabajo.',
      'hora': 'Ayer',
      'noLeidos': 0,
      'estado': 'completado',
    },
    {
      'nombre': 'Pedro Ruiz',
      'servicio': 'Gasfitería',
      'ultimoMensaje': '¿Puede venir a las 9am mañana?',
      'hora': 'Hoy 9:32 AM',
      'noLeidos': 1,
      'estado': 'pendiente',
    },
    {
      'nombre': 'Carmen Silva',
      'servicio': 'Limpieza',
      'ultimoMensaje': 'Perfecto, nos vemos el viernes',
      'hora': '2 días',
      'noLeidos': 0,
      'estado': 'programado',
    },
  ];

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'completado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'programado':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'completado':
        return 'Completado';
      case 'pendiente':
        return 'Pendiente';
      case 'programado':
        return 'Programado';
      default:
        return 'Sin estado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => context.go('/homeWorker'),
        ),
        title: const Text(
          'Chats con clientes',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body:
          mockChats.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes chats con clientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Los chats aparecerán aquí cuando\nlos clientes te contacten',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: mockChats.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final chat = mockChats[index];
                  final hasUnread = chat['noLeidos'] > 0;
                  final estadoColor = _getEstadoColor(chat['estado']);
                  final estadoText = _getEstadoText(chat['estado']);

                  return InkWell(
                    onTap: () {
                      context.go('/chatDetail', extra: chat['nombre']);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Stack(
                                children: [
                                  const CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.black,
                                    child: Icon(
                                      Icons.person_outline,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  if (hasUnread)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            chat['noLeidos'].toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            chat['nombre'],
                                            style: TextStyle(
                                              fontWeight:
                                                  hasUnread
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          chat['hora'],
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      chat['ultimoMensaje'],
                                      style: TextStyle(
                                        color:
                                            hasUnread
                                                ? Colors.black87
                                                : Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight:
                                            hasUnread
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  chat['servicio'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: estadoColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: estadoColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      estadoText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: estadoColor.withOpacity(0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
