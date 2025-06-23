import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  final List<Map<String, dynamic>> mockChats = const [
    {
      'nombre': 'Luis Rodríguez',
      'servicio': 'Electricidad',
      'ultimoMensaje': 'Nos vemos a las 4pm.',
      'hora': '10:45 AM',
      'noLeidos': 2,
    },
    {
      'nombre': 'Pedro Martínez',
      'servicio': 'Gasfitería',
      'ultimoMensaje': 'Listo el presupuesto para la reparación.',
      'hora': 'Ayer',
      'noLeidos': 0,
    },
    {
      'nombre': 'Ana García',
      'servicio': 'Limpieza',
      'ultimoMensaje': '¿Incluye productos de limpieza?',
      'hora': '2 días',
      'noLeidos': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => context.go('/homeClient'),
        ),
        title: const Text(
          'Mis chats',
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
                      'No tienes chats activos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Los chats aparecerán aquí cuando\ncontrates un servicio',
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
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final chat = mockChats[index];
                  final hasUnread = chat['noLeidos'] > 0;

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
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.black,
                                child: Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              if (hasUnread)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        chat['servicio'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: [
                                        Text(
                                          chat['hora'],
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (hasUnread) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              chat['noLeidos'].toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
